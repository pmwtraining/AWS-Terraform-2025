terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.47.0"
    }
  }
  subscription_id = " "
}

provider "azurerm" {
  features {}
}