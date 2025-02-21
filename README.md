# Azure Data Platform Infrastructure

This repository contains Terraform configurations for deploying a modern data platform on Azure, featuring Databricks and Data Lake Storage.

## Architecture

The infrastructure consists of:
- Azure Resource Group in Southeast Asia
- Azure Data Lake Storage Gen2 (Premium Storage Account)
- Azure Databricks Workspace (Premium SKU)
- Databricks Access Connector with managed identity

## Storage Layout

The storage account `momoratst01` contains three containers:
- `data`: Primary container for raw and processed data
- `metadata`: Container for metadata storage
- `history`: Container for historical data and audit logs

## Security Features

- Storage Account:
  - TLS 1.2 enforced
  - Hierarchical Namespace enabled
  - Private access for all containers
  
- Databricks:
  - Premium workspace with enhanced security features
  - Managed Identity authentication via Access Connector
  - RBAC integration with Storage Blob Data Contributor role

## Resource Naming

Resources follow a consistent naming pattern using a random pet name with prefix "momo":
- Resource Group: `<random-pet>-rg`
- Databricks Workspace: `<random-pet>-databricks`
- Access Connector: `<random-pet>-databricks-auth`

## Prerequisites

- Azure subscription
- Terraform installed
- Azure CLI installed and authenticated
- Create Service principal or equivalent
- Connect to Azure CLI wit az login

note: az login --service-principal -u "f129b20f-52e7-4df2-8aa3-ee6acb169f28" -p "WRI8Q~gux8unGcToFs0Swlmp2V8Skv_Jyj54VcSA" --tenant "3234036a-a7df-4ba8-92a0-d33f7bb6fa04"

## Usage

1. Initialize Terraform:
```bash
terraform init
```

2. Review the deployment plan:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

## Contributing

Please follow the standard Git workflow:
1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
