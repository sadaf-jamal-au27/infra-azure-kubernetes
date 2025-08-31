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

  # Remote backend configuration (commented until backend resources are created)
  # Uncomment after running ./setup_backend.sh
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "terraformstatedev2024"
  #   container_name       = "tfstate"
  #   key                  = "dev/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
  subscription_id = "a72674d0-171e-41fb-bed8-d50db63bc0b4"

  # Use service principal authentication in CI/CD
  # These environment variables will be set by GitHub Actions
  use_cli = false
}
