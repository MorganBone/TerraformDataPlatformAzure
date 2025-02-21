provider "azuread" {}

# Resource Group
resource "azurerm_resource_group" "rg" {
  location = "southeastasia"
  name     = "${random_pet.prefix.id}-rg"
}

resource "random_pet" "prefix" {
  prefix = "momo"
  length = 1
}

resource "azurerm_storage_account" "st01" {
  name                     = "momoratst01"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2" 
  is_hns_enabled           = true
}

resource "azurerm_storage_container" "st01_data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.st01.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "st01_metadata" {
  name                  = "metadata"
  storage_account_name  = azurerm_storage_account.st01.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "st01_history" {
  name                  = "history"
  storage_account_name  = azurerm_storage_account.st01.name
  container_access_type = "private"
}

resource "azurerm_databricks_workspace" "dbw" {
  name                = "${random_pet.prefix.id}-databricks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                = "premium"

  tags = {
    Environment = "Development"
  }
}

# Create Databricks Access Connector
resource "azurerm_databricks_access_connector" "auth" {
  name                = "${random_pet.prefix.id}-databricks-auth"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  identity {
    type = "SystemAssigned"
  }
}

# Assign Storage Blob Data Contributor role to the Access Connector
resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.st01.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.auth.identity[0].principal_id
}

