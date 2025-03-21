variable "environments" {
  description = "Environment name for resource deployment (e.g., dev, test, preprod, prod)"
  type        = string
  default     = "dev"
}

variable "location_shortname" {
  description = "Short name code for the Azure region (e.g., 'ne' for Northeast)"
  type        = string
  default     = "ne"
}

variable "project_name" {
  description = "Project name used in resource naming conventions"
  type        = string
  default     = "datastrategy"
}

variable "project_name_shortname" {
  description = "Project short name used in resource naming conventions"
  type        = string
  default     = "ds"
}

variable "datasource" {
  description = "Source system identifier for data ingestion"  
  type        = list(string)
  default     = ["ln7", "ln107"]
}

variable "storage_containers" {
  description = "List of storage container names to create"
  type        = list(string)
  default     = ["data","metadata","logs"]
}