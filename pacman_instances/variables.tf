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
# 

variable "subscription_id" {
  description = "Subscription ID"
  default =
}

variable "tenant_id" {
  description = "Tenant ID"
  default =
}

variable "client_id" {
  description = "Client ID"
  default =
}

variable "client_secret" {
  description = "Client secret password"
  default =
}

variable "location" {
  description = "Geo Region"
  default = "Central US"
}

variable "hostname" {
  description = "The hostname of the new VM to be configured"
  default     = "terratest-vm"
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
