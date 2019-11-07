provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A RESOURCE GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_resource_group" "dx01" {
  name     = "${var.prefix}01-resource"
  location = "${var.location}"
}

resource "azurerm_resource_group" "dx02" {
  name     = "${var.prefix}02-resource"
  location = "${var.location}"
}

resource "azurerm_resource_group" "dx03" {
  name     = "${var.prefix}03-resource"
  location = "${var.location}"
}

