###            ###
# Security Rules #
###            ###


# DX VPN Server  Network Security Group
resource "azurerm_network_security_group" "vpn-sg" {
  name                = "${var.vpn_hub-sg}"
  location            = "${azurerm_resource_group.vpn_hub_vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
}

# DX Windows 10 Desktop Network Security Group
resource "azurerm_network_security_group" "client-sg" {
  name                = "${var.client-sg}"
  location            = "${azurerm_resource_group.vpn_hub_vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
}

# NOTE: //Here opened remote desktop port client-sg
resource "azurerm_network_security_rule" "RDP" {
  name                        = "RDP"
  resource_group_name         = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  network_security_group_name = "${azurerm_network_security_group.client-sg.name}"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# NOTE: //Opened WinRM Port Windows client-sg
resource "azurerm_network_security_rule" "WinRM" {
  name                        = "WinRM"
  resource_group_name         = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  network_security_group_name = "${azurerm_network_security_group.client-sg.name}"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5985"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# NOTE: //Opened Outbound WinRM Port Windows client-sg
resource "azurerm_network_security_rule" "WinRM-out" {
  name                        = "WinRM-out"
  resource_group_name         = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  network_security_group_name = "${azurerm_network_security_group.client-sg.name}"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5985"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# NOTE: //Opened HTTPS port client-sg
resource "azurerm_network_security_rule" "windows10_HTTPS" {
  name                        = "HTTPS"
  resource_group_name         = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  network_security_group_name = "${azurerm_network_security_group.client-sg.name}"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# NOTE: this allows SSH from any network dx_vpn-sg
resource "azurerm_network_security_rule" "vpn_ssh" {
  name                        = "PermitSSHInbound"
  resource_group_name         = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
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

# NOTE: this allows VPN from Internet vpn-sg
resource "azurerm_network_security_rule" "openvpn_Port" {
  name                        = "PermitOpenVPNInbound"
  resource_group_name         = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
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

# NOTE: this allows HTTPS access to client ovpn file from Internet vpn-sg
resource "azurerm_network_security_rule" "vpn_HTTPS" {
  name                        = "HTTPS"
  resource_group_name         = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  network_security_group_name = "${azurerm_network_security_group.vpn-sg.name}"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# NOTE: this allows HTTPS access to client ovpn file from Internet vpn-sg
resource "azurerm_network_security_rule" "vpn_HTTP" {
  name                        = "HTTP"
  resource_group_name         = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  network_security_group_name = "${azurerm_network_security_group.vpn-sg.name}"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}
