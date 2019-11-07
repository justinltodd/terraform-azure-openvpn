# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# CREDENTIALS ---------------------------------------------------------------------------------------------------------
variable "subscription_id" {
  description = "Subscription ID"
  default = "36483a93-0c29-4b4f-89fd-2b1077a44280"
}

variable "tenant_id" {
  description = "Tenant ID"
  default = "8ce308d8-142f-4ba1-8e44-7ac446b0b300"
}

variable "client_id" {
  description = "Client ID"
  default = "29e008e2-2708-4484-9e78-9a652389124b"
}

variable "client_secret" {
  description = "Client secret password"
  default = "Mi2@/mM=4Js3l4xRv:KrCEjHlvGU]N@3"
}
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

# REGION LOCATION ---------------------------------------------------------------------------------------------------
variable "location" {
  description = "Geo Region"
  default = "Central US"
}

# ---------------------------------------------------------------------------------------------------------------------

# USERNAMES LINUX VPN SERVER ------------------------------------------------------------------------------------------
variable "vpnserver_username" {
  description = "The username to be provisioned into your VM"
  default     = "admin"

variable "vpnserver_password" {
  description = "The password to configure for SSH access"
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
  default     = "bluedx-demo01"
}

# ---------------------------------------------------------------------------------------------------------------------

# VM VPN SERVER SETTINGS - SIZE,NIC,KEYS,ETC -------------------------------------------------------------------------------
variable "vpnserver_vmsize" {
  description = "Size of the VMs"
  default     = "Standard_B2ms"
}

variable "vpnserver_nic" {
  description = "Network interface vpn server"
  default     = "ifconfig01"
}

variable "build_vpnserver" {
  default = "./scripts/openvpn.sh"
}

variable "ssh_public_key_file" {
  default = "./ssh_public_keys/ovpn.pub"
}

variable "ssh_private_key_file" {
  default = "./ssh_public_keys/ovpn"
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

# ---------------------------------------------------------------------------------------------------------------------

# SECURITY GROUPS VARIABLES -------------------------------------------------------------------------------------------
variable "vpn-sg" {
  description = "Security group for Pacman OpenVPN"
  default     = "vpn-SecurityGroup"
}

# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

# PREFIX FOR RESOURCE NAMING SCHEME -----------------------------------------------------------------------------------
variable "prefix" {
  description = "The prefix that will be attached to all resources deployed"
  default     = "dx"
}
