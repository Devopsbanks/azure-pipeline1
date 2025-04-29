# Terraform Multi-Environment Deployment with Azure DevOps Pipeline

## 📘 Overview

This project demonstrates how to manage **multiple environments** (`dev`, `qa`, and `prod`) using **Terraform** with a **multi-stage Azure DevOps YAML pipeline**. It leverages **pipeline templates** to keep the code **modular, reusable, and clean**.

---

## 🚀 Use Case

If you need to deploy infrastructure across multiple environments and ensure changes are promoted **sequentially** (i.e., Dev → QA → Prod), this setup is for you.

---

## 🛠️ Key Concepts

### 🔁 Template Reuse

A **template** is a YAML file that contains repetitive or reusable logic — for example:

- `terraform init`
- `terraform plan`
- `terraform apply`

These steps are written once inside a template file (e.g., `terraform-template.yml`), and called in each stage of the main pipeline.

This reduces duplication and keeps the main pipeline **short, clean, and easy to manage**.

---===========================================================================
## Folder structure

.
├── environments/
│   ├── dev/
│   ├── qa/
│   └── prod/
│
├── modules/
│   └── rg_module/
│
├── pipelines/
│   ├── azure-pipeline.yml
│   └── templates/
│       └── terraform-template.yml

================================================================================


## 🏗️ Pipeline Structure

azure-pipeline.yml

# This pipeline triggers only when changes are pushed to the 'main' branch
trigger:
  branches:
    include:
      - main

# Specify the self-hosted agent pool to run the jobs
pool: selfhostedpool

stages:
  # ========================
  # Stage 1: Dev Deployment
  # ========================
  - stage: Dev
    jobs:
      # Use reusable template for Terraform steps
      # Parameters:
      #   environment = dev (used for naming, state file, etc.)
      #   tfFolder    = path to Terraform config specific to dev environment
      - template: templates/terraform-template.yml
        parameters:
          environment: 'dev'
          tfFolder: 'environments/dev'

  # ========================
  # Stage 2: QA Deployment
  # ========================
  - stage: QA
    dependsOn: Dev  # This stage runs only if Dev stage is successful
    jobs:
      - template: templates/terraform-template.yml
        parameters:
          environment: 'qa'
          tfFolder: 'environments/qa'

  # ==========================
  # Stage 3: Prod Deployment
  # ==========================
  - stage: Prod
    dependsOn: QA  # This stage runs only if QA stage is successful
    jobs:
      - template: templates/terraform-template.yml
        parameters:
          environment: 'prod'
          tfFolder: 'environments/prod'

===========================================================================================
terraform-template.yml

# Define input parameters that will be passed from the main pipeline
parameters:
  - name: environment       # Environment name (dev, qa, prod)
    type: string
  - name: tfFolder          # Folder path where environment-specific Terraform configs are stored
    type: string

jobs:
  - job: Terraform_${{ parameters.environment }}  # Job name dynamically includes environment name
    displayName: "Terraform ${{ parameters.environment }}"  # Displayed name in Azure DevOps UI

    steps:
      # ---------------------------------
      # Step 1: Terraform Init
      # ---------------------------------
      - task: TerraformTask@5
        displayName: Terraform Init
        inputs:
          provider: 'azurerm'
          command: 'init'
          backendServiceArm: 'Azure subscription 1(your subscription id)'  # Azure service connection
          backendAzureRmResourceGroupName: 'infra-rg'                # Resource Group for storing state
          backendAzureRmStorageAccountName: 'mystorageaccount199546' # Storage Account name
          backendAzureRmContainerName: 'mycontainer'                 # Blob container name
          backendAzureRmKey: '${{ parameters.environment }}.tfstate' # Unique state file per environment
          workingDirectory: '$(System.DefaultWorkingDirectory)/${{ parameters.tfFolder }}'  # Target folder for Terraform

      # ---------------------------------
      # Step 2: Terraform Plan
      # ---------------------------------
      - task: TerraformTask@5
        displayName: Terraform Plan
        inputs:
          provider: 'azurerm'
          command: 'plan'
          environmentServiceNameAzureRM: 'Azure subscription 1(your subscription id)'  # Same service connection
          workingDirectory: '$(System.DefaultWorkingDirectory)/${{ parameters.tfFolder }}'  # Target config directory



