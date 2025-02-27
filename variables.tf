
variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "northeurope"
}

variable "naming_location_shortname" {
  description = "Short name code for the Azure region (e.g., 'ne' for Northeast)"
  type        = string
  default     = "ne"
}

variable "naming_project_name" {
  description = "Project name used in resource naming conventions"
  type        = string
  default     = "datastrategy"
}

variable "environments" {
  description = "Environment name for resource deployment (e.g., dev, test, preprod, prod)"
  type        = string
  default     = "dev"
#  type        = list(string)
#  default     = ["dev", "test", "preprod", "prod"]
}

variable "datasource" {
  description = "Source system identifier for data ingestion"  
  # type        = string
  # default     = "ln7"
  type        = list(string)
  default     = ["ln7", "ln107", "mes", "sf",]
}

variable "storage_account_tier" {
  description = "Performance tier for the storage account (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication" {
  description = "Data replication strategy for the storage account (LRS, GRS, etc.)"
  type        = string
  default     = "GRS"
}

variable "storage_containers" {
  description = "List of storage container names to create"
  type        = list(string)
  default     = ["data", "metadata", "logs"]
}

variable "min_tls_version" {
  description = "Minimum TLS version required for the storage account"
  type        = string
  default     = "TLS1_2"
}
