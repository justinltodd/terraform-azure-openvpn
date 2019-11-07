# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.dx01.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "terraform_dx01_vpn_storage" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.dx01.name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "vpnserver: ${var.vpnserver_hostname}"
  }
}

# Create openvpn virtual machine
resource "azurerm_virtual_machine" "openvpn" {
  name                  = "${var.vpnserver_hostname}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.dx01.name}"
  network_interface_ids = ["${azurerm_network_interface.vpnserver_nic.id}"]
  vm_size               = "${var.vpnserver_vmsize}"

  storage_os_disk {
    name              = "${var.vpnserver_hostname}_os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.vpnserver_hostname}"
    admin_username = "${var.vpnserver_username}"
    admin_password = "${var.vpnserver_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.vpnserver_username}/.ssh/authorized_keys"
      key_data = "${file(var.public_key_file)}"
    }
  }

  connection {
    type        = "ssh"
    host        = "${azurerm_public_ip.PublicIP.ip_address}"
    user        = "${var.vpnserver_username}"
    private_key = "${file(var.private_key_file)}"
  }

  provisioner "file" {
    content     = "${data.template_file.deployment_shell_script.rendered}"
    destination = "/tmp/userdata.sh"
  }

}
