terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.41.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }

  # Remote backend for shared state management (temporarily disabled)
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-backend"
  #   storage_account_name = "tfbackend82146"
  #   container_name       = "tfstate"
  #   key                  = "staging/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
  subscription_id = "8cbf7ca1-02c5-4b17-aa60-0a669dc6f870"
  tenant_id       = "0fc07ff0-d314-4e80-aed7-2dddffabbec7"
  use_cli         = false
}
