# VPN Hub Network Configuration


# VPN Hub Virtual Network Subnet 10.0.0.0 - 10.0.0.15
resource "azurerm_virtual_network" "vpn_hub_vnet" {
  name                = "${var.prefix-vpn-hub}-vnet"
  location            = "${azurerm_resource_group.vpn_hub_vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  address_space       = ["10.0.0.0/8"]
  dns_servers         = ["${var.VPN_DNS1}", "${var.VPN_DNS2}"]

  tags = {
    environment = "VPN Hub"
  }
}

# VPN Hub Gateway subnet
resource "azurerm_subnet" "vpn_hub_gateway_subnet" {
  name                 = "${var.prefix-vpn-hub}-gateway-subnet"
  resource_group_name  = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vpn_hub_vnet.name}"
  address_prefix       = "${var.VPN_HUB["SUBNET"]}/28"
}

# Subnet for vpnserver instance 10.0.0.15 - 10.0.0.31
resource "azurerm_subnet" "vpn_hub_vpn_subnet" {
  name                 = "${var.prefix-vpn-hub}-vpn-subnet"
  resource_group_name  = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vpn_hub_vnet.name}"
  address_prefix       = "10.1.0.16/28"
}

# Subnet for Management instances 10.0.0.32 - 10.0.0.47
resource "azurerm_subnet" "vpn_hub_mgmt_subnet" {
  name                 = "${var.prefix-vpn-hub}-mgmt-subnet"
  resource_group_name  = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vpn_hub_vnet.name}"
  address_prefix       = "10.1.0.32/28"
}

# Subnet for client instances 10.0.0.128 - 10.0.0.255
resource "azurerm_subnet" "vpn_hub_client_subnet" {
  name                 = "${var.prefix-vpn-hub}-client-subnet"
  resource_group_name  = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vpn_hub_vnet.name}"
  address_prefix       = "10.1.0.128/25"
}
