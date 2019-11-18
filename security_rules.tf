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





## NOT IN USE YET BELOW##

variable "rules" {
  description = "Standard set of predefined rules"
  type        = "map"

  # [direction, access, protocol, source_port_range, destination_port_range, description]"
  # The following info are in the submodules: source_address_prefix, destination_address_prefix
  default = {
    #ActiveDirectory
    #ActiveDirectory-AllowADReplication          = ["Inbound", "Allow", "*", "*", "389", "AllowADReplication"]
    #ActiveDirectory-AllowADReplicationSSL       = ["Inbound", "Allow", "*", "*", "636", "AllowADReplicationSSL"]
    #ActiveDirectory-AllowADGCReplication        = ["Inbound", "Allow", "TCP", "*", "3268", "AllowADGCReplication"]
    #ActiveDirectory-AllowADGCReplicationSSL     = ["Inbound", "Allow", "TCP", "*", "3269", "AllowADGCReplicationSSL"]
    #ActiveDirectory-AllowDNS                    = ["Inbound", "Allow", "*", "*", "53", "AllowDNS"]
    #ActiveDirectory-AllowKerberosAuthentication = ["Inbound", "Allow", "*", "*", "88", "AllowKerberosAuthentication"]
    #ActiveDirectory-AllowADReplicationTrust     = ["Inbound", "Allow", "*", "*", "445", "AllowADReplicationTrust"]
    #ActiveDirectory-AllowSMTPReplication        = ["Inbound", "Allow", "TCP", "*", "25", "AllowSMTPReplication"]
    #ActiveDirectory-AllowRPCReplication         = ["Inbound", "Allow", "TCP", "*", "135", "AllowRPCReplication"]
    #ActiveDirectory-AllowFileReplication        = ["Inbound", "Allow", "TCP", "*", "5722", "AllowFileReplication"]
    #ActiveDirectory-AllowWindowsTime            = ["Inbound", "Allow", "UDP", "*", "123", "AllowWindowsTime"]
    #ActiveDirectory-AllowPasswordChangeKerberes = ["Inbound", "Allow", "*", "*", "464", "AllowPasswordChangeKerberes"]
    #ActiveDirectory-AllowDFSGroupPolicy         = ["Inbound", "Allow", "UDP", "*", "138", "AllowDFSGroupPolicy"]
    #ActiveDirectory-AllowADDSWebServices        = ["Inbound", "Allow", "TCP", "*", "9389", "AllowADDSWebServices"]
    #ActiveDirectory-AllowNETBIOSAuthentication  = ["Inbound", "Allow", "UDP", "*", "137", "AllowNETBIOSAuthentication"]
    #ActiveDirectory-AllowNETBIOSReplication     = ["Inbound", "Allow", "TCP", "*", "139", "AllowNETBIOSReplication"]

    #Cassandra
    #    Cassandra = ["Inbound", "Allow", "TCP", "*", "9042", "Cassandra"]

    #Cassandra-JMX
    #    Cassandra-JMX = ["Inbound", "Allow", "TCP", "*", "7199", "Cassandra-JMX"]

    #Cassandra-Thrift
    #    Cassandra-Thrift = ["Inbound", "Allow", "TCP", "*", "9160", "Cassandra-Thrift"]

    #CouchDB
    #    CouchDB = ["Inbound", "Allow", "TCP", "*", "5984", "CouchDB"]

    #CouchDB-HTTPS
    #    CouchDB-HTTPS = ["Inbound", "Allow", "TCP", "*", "6984", "CouchDB-HTTPS"]

    #DNS-TCP
    #    DNS-TCP = ["Inbound", "Allow", "TCP", "*", "53", "DNS-TCP"]

    #DNS-UDP
    #    DNS-UDP = ["Inbound", "Allow", "UDP", "*", "53", "DNS-UDP"]

    #DynamicPorts
    #    DynamicPorts = ["Inbound", "Allow", "TCP", "*", "49152-65535", "DynamicPorts"]

    #ElasticSearch
    #    ElasticSearch = ["Inbound", "Allow", "TCP", "*", "9200-9300", "ElasticSearch"]

    #FTP
    #    FTP = ["Inbound", "Allow", "TCP", "*", "21", "FTP"]

    #HTTP
    #    HTTP = ["Inbound", "Allow", "TCP", "*", "80", "HTTP"]

    #HTTPS
    HTTPS = ["Inbound", "Allow", "TCP", "*", "443", "HTTPS"]

    #IMAP
    #    IMAP = ["Inbound", "Allow", "TCP", "*", "143", "IMAP"]

    #IMAPS
    #    IMAPS = ["Inbound", "Allow", "TCP", "*", "993", "IMAPS"]

    #Kestrel
    #    Kestrel = ["Inbound", "Allow", "TCP", "*", "22133", "Kestrel"]

    #LDAP
    #    LDAP = ["Inbound", "Allow", "TCP", "*", "389", "LDAP"]

    #MongoDB
    #    MongoDB = ["Inbound", "Allow", "TCP", "*", "27017", "MongoDB"]

    #Memcached
    #    Memcached = ["Inbound", "Allow", "TCP", "*", "11211", "Memcached"]

    #MSSQL
    #    MSSQL = ["Inbound", "Allow", "TCP", "*", "1433", "MSSQL"]

    #MySQL
    #    MySQL = ["Inbound", "Allow", "TCP", "*", "3306", "MySQL"]

    #RabbitMQ
    #   RabbitMQ = ["Inbound", "Allow", "TCP", "*", "5672", "RabbitMQ"]

    #RDP
    RDP = ["Inbound", "Allow", "TCP", "*", "3389", "RDP"]

    #Redis
    #    Redis = ["Inbound", "Allow", "TCP", "*", "6379", "Redis"]

    #SMTP
    #    SMTP = ["Inbound", "Allow", "TCP", "*", "25", "SMTP"]

    #SMTPS
    #    SMTPS = ["Inbound", "Allow", "TCP", "*", "465", "SMTPS"]

    #SSH
    SSH = ["Inbound", "Allow", "TCP", "*", "22", "SSH"]

    #WinRM
    WinRM = ["Inbound", "Allow", "TCP", "*", "5986", "WinRM"]
  }
}
