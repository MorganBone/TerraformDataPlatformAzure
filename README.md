# Azure Data Platform Infrastructure

This repository contains Terraform configurations for deploying a modern data platform on Azure, featuring Databricks and Data Lake Storage.

## TODO

1- Create environments (DEV-QA-PROD) --> https://dev.to/pwd9000/multi-environment-azure-deployments-with-terraform-and-github-2450
2- Review Architecture to be modular -> compute/network/storage/...
3- High availablilty duplicate in 2 Availablity Zones
4- Review storage security public_network_access_enabled --> False
5- Review network
  5.1- DNS or Load balancer for storage ?
  5.2- VNETs

## Architecture

The infrastructure consists of:
- Azure Resource Group in Southeast Asia
- Azure Data Lake Storage Gen2 (Premium Storage Account)
- Azure Databricks Workspace (Premium SKU)
- Databricks Access Connector with managed identity

## Opened Questions

1) storage_account_replication: 
  - LRS (Locally Redundant Storage)
  - ZRS (Zone-Redundant Storage) ***
  - GRS (Geo-Redundant Storage)
  - GZRS (Geo-Zone-Redundant Storage)
  - RAGZRS (Read Access Geo-Zone-Redundant Storage)
  - RAGRS (Read Access Geo-Redundant Storage)
  
  doc: https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy

## Documentation
Terraform registry (Azure): https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs