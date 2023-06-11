terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.59.0"
    }
  }
}

#Configure the Moicrosoft Azure Provider
provider "azurerm" {
  features {}
}

#Generate a random integer so we can use it in the names of the resources below
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}


resource "azurerm_resource_group" "rg" {
  name     = "TaskBoardRG-${random_integer.ri.result}"
  location = "West Europe"
}


resource "azurerm_service_plan" "appsp" {
  name                = "task-board-plan-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}


resource "azurerm_linux_web_app" "appservice" {
  name                = "task-board-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.appsp.location
  service_plan_id     = azurerm_service_plan.appsp.id


  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }

  connection_string {
    name  = "Default Connection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sql.name};User ID=${azurerm_mssql_server.sqlserver.administrator_login};Password=${azurerm_mssql_server.sqlserver.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }
}


resource "azurerm_app_service_source_control" "git" {
  app_id                 = azurerm_linux_web_app.appservice.id
  repo_url               = "https://github.com/nakov/ContactBook"
  branch                 = "main"
  use_manual_integration = true
}


resource "azurerm_mssql_server" "sqlserver" {
  name                         = "task-board-sql-${random_integer.ri.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "missadministrator"
  administrator_login_password = "thisIsKat11"
}


resource "azurerm_mssql_database" "sql" {
  name           = "TaskBoardDB-${random_integer.ri.result}"
  server_id      = azurerm_mssql_server.sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  read_scale     = true
  sku_name       = "S0"
  zone_redundant = true

  tags = {
    foo = "bar"
  }
}


resource "azurerm_mssql_firewall_rule" "example" {
  name             = "TaskBoardFWR-${random_integer.ri.result}"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
