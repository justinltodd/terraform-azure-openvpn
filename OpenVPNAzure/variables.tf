variable "subscription_id" {
  default =
}

variable "tenant_id" {
  default =
}

variable "client_id" {
  default =
}

variable "client_secret" {
  default =
}

variable "location" {
  default = "Central US"
}

variable "hostname" {
  default = "openvpn"
}

variable "admin_username" {
  default = "ubuntu"
}

variable "private_key_file" {
  default = "../certs/ovpn"
}

variable "public_key_file" {
  default = "../certs/ovpn.pub"
}

variable "client_config_path" {
  default = "../client_configs"
}

variable "client_config_name" {
  default = "azure-ovpn-client"
}

variable "cert_details" {
  default = "../cert_details"
}
