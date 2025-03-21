variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "northeurope"
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

variable "entra_groups_prefix_name" {
  description = "Prefix for project Entra Groups"
  type        = string
  default     = "WSA-EntraGRP-BI-"
}

variable "entra_groups" {
  description = "List of admins group roles to create"
  type        = list(string)
  default     = ["devs", "users", "admins", "support"]
}

variable "project_admins_userslist" {
  description = "List of Entra ID group roles to create"
  type        = list(string)
  default     = ["morgan@bonemorgangmail.onmicrosoft.com"]
}

variable "project_support_userslist" {
  description = "List of Entra ID group roles to create"
  type        = list(string)
  default     = ["morgan@bonemorgangmail.onmicrosoft.com"]
}

variable "project_users_userslist" {
  description = "List of Entra ID group roles to create"
  type        = list(string)
  default     = ["morgan@bonemorgangmail.onmicrosoft.com"]
}

variable "project_devs_userslist" {
  description = "List of Entra ID group roles to create"
  type        = list(string)
  default     = ["morgan@bonemorgangmail.onmicrosoft.com"]
}

# #############################
# Tagging variables 
# #############################

variable "WSA-Environment" {
  description = "WSA environment classification"
  type        = string
  default     = "NonProd"
}

variable "WSA-PrimaryOwner" {
  description = "Primary owner contact email"
  type        = string
  default     = ""
}

variable "WSA-SecondaryOwner" {
  description = "Secondary owner contact email"
  type        = string
  default     = ""
}

variable "WSA-ProductName" {
  description = "Product name for resource tagging"
  type        = string
  default     = ""
}

variable "WSA-CostCenterName" {
  description = "Cost center name for billing"
  type        = string
  default     = ""
}

variable "WSA-CostCenterCode" {
  description = "Cost center code for billing"
  type        = string
  default     = ""
}

variable "WSA-Description" {
  description = "Description of the resource purpose"
  type        = string
  default     = ""
}

variable "WSA-IT-ServiceOwner" {
  description = "IT Service Owner contact"
  type        = string
  default     = ""
}

variable "WSA-IT-Environment" {
  description = "IT Environment"
  type        = string
  default     = ""
}

variable "WSA-IT-Service" {
  description = "IT Service classification"
  type        = string
  default     = ""
}

variable "WSA-IT-ProjectName" {
  description = "IT Project Name"
  type        = string
  default     = ""
}
