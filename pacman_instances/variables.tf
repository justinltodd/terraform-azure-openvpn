# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------


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

variable "location" {
  description = "Geo Region"
  default = "Central US"
}

variable "vpnserver_hostname" {
  description = "The hostname of the openvpn server VM to be configured"
  default     = "pacmanvpn"
}

variable "pacman_hostname" {
  description = "The hostname of the new VM pacman desktop to be configured"
  default     = "pacman01"
}

variable "username" {
  description = "The username to be provisioned into your VM"
  default     = "pacman"

variable "password" {
  description = "The password to configure for SSH access"
  default     = "Password1234"
}

variable "prefix" {
  description = "The prefix that will be attached to all resources deployed"
  default     = "pacman"
}
