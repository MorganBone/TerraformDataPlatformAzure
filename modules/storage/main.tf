
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
