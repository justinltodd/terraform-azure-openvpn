# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A VIRTUAL NETWORK RESOURCES
# ---------------------------------------------------------------------------------------------------------------------

# Virtual Network 
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.virtual_network}"
  address_space       = ["10.0.0.0/8"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.dx01.name}"
}

# Gateway subnet
resource "azurerm_subnet" "GatewaySubnet" {
  name                 = "${var.gateway_subnet}"
  resource_group_name  = "${azurerm_resource_group.dx01.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.1.0.0/24"
}

# Management backend subnet for administrative purposes
resource "azurerm_subnet" "management" {
  name                 = "${var.mgmt_backend_subnet}"
  resource_group_name  = "${azurerm_resource_group.dx01.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.2.0.0/24"
}

# First initial subnet for dx windows 10 instances
resource "azurerm_subnet" "frontend" {
  name                 = "${var.vpn_frontend_subnet}"
  resource_group_name  = "${azurerm_resource_group.dx01.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.3.0.0/24"
}

# DX VPN Server  Network Security Group
resource "azurerm_network_security_group" "vpn-sg" {
  name                = "${var.vpn-sg}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.dx01.name}"
}

# DX Windows 10 Desktop Network Security Group
resource "azurerm_network_security_group" "windows10-sg" {
  name                = "${var.dx_windows10-sg}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.dx01.name}"
}

# NOTE: //Here opened remote desktop port windows10-sg
resource "azurerm_network_security_rule" "RDP" {
  name                        = "RDP"
  resource_group_name         = "${azurerm_resource_group.dx01.name}"
  network_security_group_name = "${azurerm_network_security_group.windows10-sg.name}"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# NOTE: //Opened WinRM Port Windows windows10-sg
resource "azurerm_network_security_rule" "WinRM" {
  name                        = "WinRM"
  resource_group_name         = "${azurerm_resource_group.dx01.name}"
  network_security_group_name = "${azurerm_network_security_group.windows10-sg.name}"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5985"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# NOTE: //Opened Outbound WinRM Port Windows windows10-sg
resource "azurerm_network_security_rule" "WinRM-out" {
  name                        = "WinRM-out"
  resource_group_name         = "${azurerm_resource_group.dx01.name}"
  network_security_group_name = "${azurerm_network_security_group.windows10-sg.name}"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5985"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# NOTE: //Opened HTTPS port windows10-sg
resource "azurerm_network_security_rule" "HTTPS" {
  name                        = "HTTPS"
  resource_group_name         = "${azurerm_resource_group.dx01.name}"
  network_security_group_name = "${azurerm_network_security_group.windows10-sg.name}"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# NOTE: this allows SSH from any network vpn-sg
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

# NOTE: this allows VPN from Internet vpn-sg
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

# NOTE: this allows HTTPS access to client ovpn file from Internet vpn-sg
resource "azurerm_network_security_rule" "HTTPS" {
  name                        = "HTTPS"
  resource_group_name         = "${azurerm_resource_group.dx01.name}"
  network_security_group_name = "${azurerm_network_security_group.vpn-sg.name}"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# VPNSERVER PublicIP
resource "azurerm_public_ip" "PublicIP" {
  name                         = "${var.vpnserver_hostname}-public"
  resource_group_name          = "${azurerm_resource_group.dx01.name}"
  location                     = "${var.location}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.vpnserver_hostname}"  #//adds dns using hostname.centralus.cloudapp.azure.com

  tags = {
    environment = "VPN Server: ${var.vpnserver_hostname}"
}

# VPNSERVER Network Interface
resource "azurerm_network_interface" "vpnserver_nic" {
  name                      = "${var.vpnserver_hostname}Nic01"
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

# Create windows 10 desktop IPs
resource "azurerm_public_ip" "dx_PublicIP" {
  name                = "${var.windows_hostname}-public"
  resource_group_name = "${azurerm_resource_group.dx01.name}"
  location            = "${var.location}"
  allocation_method   = "Dynamic"

  tags = {
    environment = "Windows 10 Desktop: ${var.windows_hostname}"
  }
}

# Create windows 10 desktop network interface
resource "azurerm_network_interface" "dx-WindowsNic" {
  name                      = "${var.windows_hostname}Nic01"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.dx01.name}"
  network_security_group_id = "${azurerm_network_security_group.windows10-sg.id}"

  ip_configuration {
    name                          = "${var.windows_hostname}"
    subnet_id                     = "${azurerm_subnet.frontend.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.dx_PublicIP.id}"
  }

  tags = {
    environment = "Windows 10 Desktop: ${var.windows_hostname}"
  }
}
