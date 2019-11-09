output "public_ip" {
  value = "The VPN Public IP Address: ${azurerm_public_ip.PublicIP.ip_address}"
}
