provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A RESOURCE GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_resource_group" "vpn_hub_vnet-rg" {
  name     = "${var.prefix-vpn-hub}-rg"
  location = "${var.location}"
}

resource "azurerm_resource_group" "spoke01_vnet-rg" {
  name     = "${var.prefix-spoke}01-rg"
  location = "${var.location}"
}

resource "azurerm_resource_group" "spoke02_vnet-rg" {
  name     = "${var.prefix-spoke}02-rg"
  location = "${var.location}"
}

