provider "azuread" {}

data "azurerm_subscription" "current" {}

locals {
  subscription_name = lower(data.azurerm_subscription.current.display_name)
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = "${local.subscription_name}-${var.naming_project_name}-bi-${var.environments}-rg"
}

# Create storage accounts sequentially with delay
resource "time_sleep" "wait_30_seconds" {
  depends_on = [azurerm_resource_group.rg]
  create_duration = "30s"
}

resource "azurerm_storage_account" "st" {
  for_each                 = toset(var.datasource)
  depends_on               = [time_sleep.wait_30_seconds]
  name                     = replace("st${var.naming_project_name}${var.environments}${each.value}01", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication
  min_tls_version         = var.min_tls_version
  is_hns_enabled          = true

  identity {
    type = "SystemAssigned"
  }
}

# Dynamic container creation for each storage account
resource "azurerm_storage_container" "containers" {
  for_each               = {
    for pair in setproduct(var.datasource, var.storage_containers) : "${pair[0]}-${pair[1]}" => {
      storage_account = pair[0]
      container_name = pair[1]
    }
  }
  name                   = each.value.container_name
  storage_account_name   = azurerm_storage_account.st[each.value.storage_account].name
  container_access_type  = "private"
}

resource "azurerm_databricks_workspace" "dbw" {
  name                = "dbw-${var.naming_project_name}-${var.environments}-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                = "premium"

  tags = {
    Environment = "Development"
  }
}

# Create Databricks Access Connector
resource "azurerm_databricks_access_connector" "auth" {
  name                = "dac-${var.naming_project_name}-${var.environments}-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  identity {
    type = "SystemAssigned"
  }
}

# Assign Storage Blob Data Contributor role to the Access Connector for each storage account
resource "azurerm_role_assignment" "storage_contributor" {
  for_each              = toset(var.datasource)
  scope                = azurerm_storage_account.st[each.value].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.auth.identity[0].principal_id
}
