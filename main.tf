provider "azuread" {}

# Get current subscription
data "azurerm_subscription" "current" {}

# Get current client configuration
data "azuread_client_config" "current" {}

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
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
  for_each                 = toset(var.datasource)
  depends_on               = [time_sleep.wait_30_seconds]
  name                     = replace("st${var.naming_project_name}${var.environments}${each.value}", "-", "")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled          = true   
  access_tier             = "Hot"
  ### >>> Ayman to check security  
  # Security
  https_traffic_only_enabled = true
  min_tls_version         = "TLS1_2"
  public_network_access_enabled = true # Needed by Terraform
  shared_access_key_enabled = true # Needed by Terraform
  infrastructure_encryption_enabled = true
  ### >>> Nico and Saya to configure VNet
  # Network 
  # network_rules {
  #   default_action = "Allow"
  #   ip_rules = var.allowed_ip_addresses
  #   virtual_network_subnet_resource_id = var.vnet_subnet_id
  # }

  identity {
    type = "SystemAssigned"
  }
}



# Create containers after role assignment
resource "azurerm_storage_container" "container" {
  for_each = {
    for pair in setproduct(var.datasource, var.storage_containers) : "${pair[0]}-${pair[1]}" => {
      storage_account = pair[0]
      container_name = pair[1]
    }
  }
  name                  = each.value.container_name
  storage_account_name  = azurerm_storage_account.st[each.value.storage_account].name
  container_access_type = "private"
}

resource "azurerm_databricks_workspace" "dbw" {
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_workspace
  name                = "dbw-${var.naming_project_name}-${var.environments}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
  infrastructure_encryption_enabled = true
  public_network_access_enabled = true  # Needed by Terraform
  custom_parameters {
    no_public_ip = true

    ### >>> Nico and Saya to configure VNet
    # virtual_network_id = azurerm_virtual_network.vnet.id
    # vnet_address_prefix = azurerm_subnet.subnet.address_prefixes[0]
    # ...
  }
  # enhanced_security_compliance {
    ### >>> Ayman to check security  
    # compliance_security_profile_enabled = true
    # compliance_security_profile_standards = "Name of the standards"
    # enhanced_security_monitoring_enabled = true 
    # We do not want to enable automatic cluster update as it may create compatiblity issue in code (eg Python version, ...)
    # automatic_cluster_update_enabled = false
  # }

  tags = {
    Environment = "${var.environments}"
  }
}

# Create Databricks Access Connector - used to connect storage to Databricks - 1 per databricks workspace
resource "azurerm_databricks_access_connector" "auth" {
  name                = "dac-${var.naming_project_name}-${var.environments}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  identity {
    type = "SystemAssigned"
  }
}

# Assign Storage Blob Data Contributor role to the Access Connector for each storage account
resource "azurerm_role_assignment" "storage_contributor" {
  for_each              = toset(var.datasource)
  depends_on = [azurerm_databricks_access_connector.auth, azurerm_storage_account.st]
  scope                = azurerm_storage_account.st[each.value].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.auth.identity[0].principal_id
}

# Create Entra ID groups for each role in each environment
resource "azuread_group" "environment_groups" {
  for_each = toset(var.entra_groups)
  display_name     = "${var.entra_groups_prefix_name}-${var.naming_project_name}-${var.environments}-${each.value}"
  security_enabled = true
  description      = "Access group for ${each.value} in ${var.environments} environment of ${var.naming_project_name} project"

  owners = [
    data.azuread_client_config.current.object_id
  ]
}
