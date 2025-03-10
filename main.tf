### resources: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources

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
  # NOTE: Changing the following options will force recreation of the resource group:
  # - name
  # - location
  location = var.location
  name     = "${local.subscription_name}-${var.project_name}-bi-${var.environments}-rg"
  tags ={
    WSA-Environment = var.WSA-Environment 
    WSA-PrimaryOwner = var.WSA-PrimaryOwner
    WSA-SecondaryOwner = var.WSA-SecondaryOwner
    WSA-ProductName = var.WSA-ProductName
    WSA-CostCenterName = var.WSA-CostCenterName
    WSA-CostCenterCode = var.WSA-CostCenterCode
    WSA-Description = var.WSA-Description
    WSA-ITServiceOwner = var.WSA-IT-ServiceOwner
    WSA-ITService = var.WSA-IT-Service
    WSA-ITProjectName = var.WSA-IT-ProjectName
    }
}

# Create Key Vault
resource "azurerm_key_vault" "kv" {
  # NOTE: Changing the following options will force recreation of the key vault:
  # - name
  # - location
  # - resource_group_name
  # - tenant_id
  name                = "${var.project_name}-${var.location_shortname}-${var.environments}-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id          = data.azurerm_subscription.current.tenant_id
  sku_name           = "standard"

  # Enable RBAC for more granular access control
  enable_rbac_authorization = true
  
  # Enable purge protection (recommended for production)
  purge_protection_enabled    = true
  soft_delete_retention_days = 7

  # Network rules - restrict access
  public_network_access_enabled = true  # Temporarily enabled for initial setup
  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Allow"  # Temporarily set to Allow for initial setup
  }

}

# Grant current user Key Vault Administrator rights
resource "azurerm_role_assignment" "kv_admin" {
  # NOTE: Changing any of the following options will force recreation of the role assignment:
  # - scope
  # - role_definition_name
  # - principal_id
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azuread_client_config.current.object_id
}

# Create storage accounts sequentially with delay
resource "time_sleep" "wait_30_seconds" {
  depends_on = [azurerm_resource_group.rg]
  create_duration = "30s"
}

resource "azurerm_storage_account" "st" {
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
  # NOTE: Changing the following options will force recreation of the storage account:
  # - name
  # - resource_group_name
  # - location
  # - account_kind
  # - account_tier
  # - account_replication_type
  # - is_hns_enabled
  for_each                 = toset(var.datasource)
  depends_on               = [time_sleep.wait_30_seconds]
  name                     = replace("${var.project_name_shortname}${var.location_shortname}${var.environments}${each.value}st", "-", "")
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
  # NOTE: Changing the following options will force recreation of the storage container:
  # - name
  # - storage_account_name
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
  # NOTE: Changing the following options will force recreation of the databricks workspace:
  # - name
  # - resource_group_name
  # - location
  # - sku
  # - VNet
  name                = "${var.project_name}-${var.location_shortname}-${var.environments}-dbw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
  infrastructure_encryption_enabled = true
  public_network_access_enabled = true  # Needed by Terraform
  custom_parameters {
    no_public_ip = false # at True, this option will create custom Vnet for data plane but it is not needed if we have VNet 

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

}

# Create Databricks Access Connector - used to connect storage to Databricks - 1 per databricks workspace
resource "azurerm_databricks_access_connector" "auth" {
  # NOTE: Changing the following options will force recreation of the access connector:
  # - name
  # - resource_group_name
  # - location
  name                = "${var.project_name}-${var.location_shortname}-${var.environments}-dac"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  identity {
    type = "SystemAssigned"
  }
}

# Assign Storage Blob Data Contributor role to the Access Connector for each storage account
resource "azurerm_role_assignment" "storage_contributor" {
  # NOTE: Changing any of the following options will force recreation of the role assignment:
  # - scope
  # - role_definition_name
  # - principal_id
  for_each              = toset(var.datasource)
  depends_on = [azurerm_databricks_access_connector.auth, azurerm_storage_account.st]
  scope                = azurerm_storage_account.st[each.value].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.auth.identity[0].principal_id
}


# #####################################################################
# ENTRA Architecture
# #####################################################################

# Create admin group
resource "azuread_group" "admins_project_group" {
  # NOTE: Changing the following options will force recreation of the group:
  # - display_name
  display_name     = "${var.entra_groups_prefix_name}-${var.project_name}-${var.environments}-admins"
  security_enabled = true
  description      = "Admin access group in ${var.environments} environment of ${var.project_name} project"

  owners = [
    data.azuread_client_config.current.object_id
  ]
}

# Look up project admin users by their email addresses
data "azuread_user" "project_admins" {
  for_each            = toset(var.project_admins_userslist)
  user_principal_name = each.value
}

# Add project admins to the admin group
resource "azuread_group_member" "project_admins" {
  for_each         = toset(var.project_admins_userslist)
  # It expects group id without /groups/ prefix 
  group_object_id  = replace(azuread_group.admins_project_group.id, "//groups//", "")
  member_object_id = replace(data.azuread_user.project_admins[each.key].id, "//users//", "")
}


# Create support group
resource "azuread_group" "support_project_group" {
  # NOTE: Changing the following options will force recreation of the group:
  # - display_name
  display_name     = "${var.entra_groups_prefix_name}-${var.project_name}-${var.environments}-support"
  security_enabled = true
  description      = "support access group in ${var.environments} environment of ${var.project_name} project"

  owners = [
    data.azuread_client_config.current.object_id
  ]
}

# Look up project admin users by their email addresses
data "azuread_user" "project_support" {
  for_each            = toset(var.project_support_userslist)
  user_principal_name = each.value
}

# Add project support to the support group
resource "azuread_group_member" "project_support" {
  for_each         = toset(var.project_support_userslist)
  # It expects group id without /groups/ prefix 
  group_object_id  = replace(azuread_group.support_project_group.id, "//groups//", "")
  member_object_id = replace(data.azuread_user.project_support[each.key].id, "//users//", "")
}


# Create devs group
resource "azuread_group" "devs_project_group" {
  # NOTE: Changing the following options will force recreation of the group:
  # - display_name
  display_name     = "${var.entra_groups_prefix_name}-${var.project_name}-${var.environments}-devs"
  security_enabled = true
  description      = "Devs access group in ${var.environments} environment of ${var.project_name} project"

  owners = [
    data.azuread_client_config.current.object_id
  ]
}

# Look up project admin users by their email addresses
data "azuread_user" "project_devs" {
  for_each            = toset(var.project_devs_userslist)
  user_principal_name = each.value
}

# Add project devs to the devs group
resource "azuread_group_member" "project_devs" {
  for_each         = toset(var.project_devs_userslist)
  # It expects group id without /groups/ prefix 
  group_object_id  = replace(azuread_group.devs_project_group.id, "//groups//", "")
  member_object_id = replace(data.azuread_user.project_devs[each.key].id, "//users//", "")
}




# Create users group
resource "azuread_group" "users_project_group" {
  # NOTE: Changing the following options will force recreation of the group:
  # - display_name
  display_name     = "${var.entra_groups_prefix_name}-${var.project_name}-${var.environments}-users"
  security_enabled = true
  description      = "Users access group in ${var.environments} environment of ${var.project_name} project"

  owners = [
    data.azuread_client_config.current.object_id
  ]
}

# Look up project admin users by their email addresses
data "azuread_user" "project_users" {
  for_each            = toset(var.project_users_userslist)
  user_principal_name = each.value
}

# Add project users to the users group
resource "azuread_group_member" "project_users" {
  for_each         = toset(var.project_users_userslist)
  # It expects group id without /groups/ prefix 
  group_object_id  = replace(azuread_group.users_project_group.id, "//groups//", "")
  member_object_id = replace(data.azuread_user.project_users[each.key].id, "//users//", "")
}

