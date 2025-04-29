terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.20.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = "9117002a-2308-428d-993b-9f46dfdfd10c"
}
