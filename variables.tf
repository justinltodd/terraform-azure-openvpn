# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# PREFIX FOR RESOURCE NAMING SCHEME -----------------------------------------------------------------------------------
variable "prefix" {
  description = "The prefix that will be attached to all resources deployed"
  default     = "dx"
}

# CREDENTIALS ---------------------------------------------------------------------------------------------------------
variable "subscription_id" {
  description = "Subscription ID"
  default     = "36483a93-0c29-4b4f-89fd-2b1077a44280"
}

variable "tenant_id" {
  description = "Tenant ID"
  default     = "8ce308d8-142f-4ba1-8e44-7ac446b0b300"
}

variable "client_id" {
  description = "Client ID"
  default     = "29e008e2-2708-4484-9e78-9a652389124b"
}

variable "client_secret" {
  description = "Client secret password"
  default     = "Mi2@/mM=4Js3l4xRv:KrCEjHlvGU]N@3"
}
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

# REGION LOCATION ---------------------------------------------------------------------------------------------------
variable "location" {
  description = "Geo Region - (No spaces)"
  default     = "centralus"
}

# ---------------------------------------------------------------------------------------------------------------------

# USERNAMES VPN/Windows  ----------------------------------------------------------------------------------------------
variable "vpnserver_username" {
  description = "The username configured for linux"
  default     = "dxadmin"
}

variable "vpnserver_password" {
  description = "The password configured for linux"
  default     = "Password1234"
}

variable "windows_username" {
  description = "The username for windows account"
  default     = "dxadmin"
}

variable "windows_password" {
  description = "The password for windows account"
  default     = "Password1234"
}

# ---------------------------------------------------------------------------------------------------------------------

# HOSTNAMES -----------------------------------------------------------------------------------------------------------
variable "vpnserver_hostname" {
  description = "The hostname of the openvpn server LINUX VM to be configured"
  default     = "bluedx-vpn01"
}

variable "windows_hostname" {
  description = "The hostname of the new VM  Windows 10 desktop to be configured"
  default     = "bluedx01"
}

# ---------------------------------------------------------------------------------------------------------------------

# VM VPN SERVER SETTINGS - SIZE,NIC,KEYS,ETC --------------------------------------------------------------------------
variable "vpnserver_vmsize" {
  description = "Size of the VMs"
  default     = "Standard_B2ms"
}

variable "vpnserver_nic" {
  description = "Network interface vpn server"
  default     = "ifconfig01"
}

variable "lighttpd_template" {
  description = "lighttpd.conf build template"
  default     = "./scripts/lighttpd.conf"
}

variable "dh_pem" {
  description = "DH parameters file using the predefined ffdhe2048 group"
  default     = "./scripts/dh.pem"
}

variable "server_conf" {
  description = "VPN Server Configuration template file"
  default     = "./scripts/server.conf"
}

variable "client_template" {
  description = "VPN client ovpn template file"
  default     = "./scripts/client-common.txt"
}

variable "ssh_public_key_file" {
  description = "public ssh key"
  default     = "./ssh_keys/ovpn.pub"
}

variable "ssh_private_key_file" {
  description = "private ssh key"
  default     = "./ssh_keys/ovpn"
}

variable "client_config_path" {
  description = "client ovpn config path"
  default     = "./client_configs"
}

variable "client_config_name" {
  description = "client ovpn file name"
  default     = "bluedx-vpn01-ovpn-client"
}

variable "cert_details" {
  description = "certification details path"
  default     = "../cert_details"
}

variable "PORT" {
  description = "VPN Server Port"
  default     = "1194"
}

variable "PROTOCOL" {
  description = "Protocol for VPN Server server.conf"
  default     = "udp"
}

variable "VPNSERVER_IP" {
  description = "setting for server.conf"
  default     = "10.3.0.0"
}

variable "VPNSERVER_Subnet" {
  description = "setting for server.conf"
  default     = "255.255.255.0"
}

# VM DX Windows Desktop 10  SETTINGS - SIZE,NIC,KEYS,ETC --------------------------------------------------------------------------
variable "dx_windows10_vmsize" {
  description = "Size of the VMs"
  default     = "Standard_B2ms"
}

variable "dx_windows10_nic" {
  description = "Network interface vpn server"
  default     = "ipconfig01"
}

# NETWORK VARIABLES ---------------------------------------------------------------------------------------------------
variable "virtual_network" {
  description = "The azurerm_virtual_network name"
  default     = "dxVPNVNet"
}

variable "gateway_subnet" {
  description = "The Gateway subnet"
  default     = "GatewaySubnet"
}

variable "vpn_frontend_subnet" {
  description = "The frontend vpn client network"
  default     = "frontendSubNet"
}

variable "mgmt_backend_subnet" {
  description = "The backend network"
  default     = "mgmt_backendSubnet"
}

variable "DNS1" {
  description = "Quad9 First Primary DNS"
  default     = "9.9.9.9"
}

variable "DNS2" {
  description = "Quad9 Secondary DNS"
  default     = "149.112.112.112"
}

# ---------------------------------------------------------------------------------------------------------------------

# SECURITY GROUPS VARIABLES -------------------------------------------------------------------------------------------
variable "dx_vpn-sg" {
  description = "Security group for OpenVPN Server"
  default     = "dx_vpn-SecurityGroup"
}

variable "dx_windows10-sg" {
  description = "Security group for Windows 10 Desktop"
  default     = "dx_Windows10-SecurityGroup"
}

# ---------------------------------------------------------------------------------------------------------------------

# SECURITY RULES VARIABLES --------------------------------------------------------------------------------------------
# Custom security rules
# [priority, direction, access, protocol, source_port_range, destination_port_range, description]"
# All the fields are required.

# Predefined rules
variable "predefined_rules" {
  type    = "list"
  default = []
}

variable "custom_rules" {
  description = "Security rules for the network security group using this format name = [priority, direction, access, protocol, source_port_range, destination_port_range, source_address_prefix, destination_address_prefix, description]"
  type        = "list"
  default     = []
}

# source address prefix to be applied to all rules
variable "source_address_prefix" {
  type    = "list"
  default = ["*"]

  # Example ["10.0.3.0/24"] or ["VirtualNetwork"]
}

# Destination address prefix to be applied to all rules
variable "destination_address_prefix" {
  type    = "list"
  default = ["*"]

  # Example ["10.0.3.0/32","10.0.3.128/32"] or ["VirtualNetwork"]
}
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

