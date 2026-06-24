terraform {

  required_version = ">= 1.1.0"

  required_providers {

    azurerm = {

      source = "hashicorp/azurerm"

      version = "~> 4.0"

    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstatepramod23062026"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"

    use_azuread_auth = true

  }
}

provider "azurerm" {

  features {}

}

