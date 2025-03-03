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
}

variable "datasource" {
  description = "Source system identifier for data ingestion"  
  type        = list(string)
  default     = ["ln7", "ln107"]
}

variable "storage_containers" {
  description = "List of storage container names to create"
  type        = list(string)
  default     = ["data", "metadata", "logs"]
}

variable "entra_groups" {
  description = "List of Entra ID group roles to create"
  type        = list(string)
  default     = ["dev", "users", "admin", "support"]
}

variable "entra_groups_prefix_name" {
  description = "Prefix for project Entra Groups"
  type        = string
  default     = "WSA-EntraGRP-BI-"
}