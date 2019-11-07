# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A VIRTUAL NETWORK RESOURCES
# See test/terraform_azure_example_test.go for how to write automated tests for this code.
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.virtual_network}"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.dx01.name}"
}

resource "azurerm_subnet" "GatewaySubnet" {
  name                 = "${var.gateway_subnet}"
  resource_group_name  = "${azurerm_resource_group.dx01.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_subnet" "frontend" {
  name                 = "${var.vpn_frontend_subnet}"
  resource_group_name  = "${azurerm_resource_group.dx01.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_subnet" "management" {
  name                 = "${var.mgmt_backend_subnet}"
  resource_group_name  = "${azurerm_resource_group.dx01.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.3.0/24"
}

resource "azurerm_network_security_group" "vpn-sg" {
  name                = "${var.vpn-sg}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.dx01.name}"
}

# NOTE: this allows SSH from any network
resource "azurerm_network_security_rule" "ssh" {
  name                        = "PermitSSHInbound"
  resource_group_name         = "${azurerm_resource_group.dx01.name}"
  network_security_group_name = "${azurerm_network_security_group.vpn-sg.name}"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# NOTE: this allows VPN from Internet
resource "azurerm_network_security_rule" "openvpn" {
  name                        = "PermitOpenVPNInbound"
  resource_group_name         = "${azurerm_resource_group.dx01.name}"
  network_security_group_name = "${azurerm_network_security_group.vpn-sg.name}"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "1194"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "PublicIP" {
  name                         = "${var.vpnserver_hostname}-public"
  resource_group_name          = "${azurerm_resource_group.dx01.name}"
  location                     = "${var.location}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "nic" {
  name                      = "${var.vpnserver_hostname}"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.dx01.name}"
  network_security_group_id = "${azurerm_network_security_group.vpn-sg.name}"

  ip_configuration {
    name                          = "${var.vpnserver_hostname}"
    subnet_id                     = "${azurerm_subnet.frontend.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.PublicIP.id}"
  }
}


