output "vpnserver_public_ip" {
  value = "The VPN Public IP Address: ${azurerm_public_ip.PublicIP.ip_address}"
}

output "vpnserver_private_ip" {
  value = "The VPN Private IP Address: ${azurerm_network_interface.vpnserver_nic.private_ip_address}"
}
