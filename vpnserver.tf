# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.dx01.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "dx_vpn_storage" {
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
      key_data = "${file(var.ssh_public_key_file)}"
    }
  }

  connection {
    type        = "ssh"
    host        = "${azurerm_public_ip.PublicIP.ip_address}"
    user        = "${var.vpnserver_username}"
    private_key = "${file(var.private_key_file)}"
  }

  provisioner "file" {
    content     = "${var.build_vpnserver}"
    destination = "/tmp/${var.build_vpnserver}"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/${var.build_vpnserver}",
      "sudo /tmp/${var.build_vpnserver} --adminpassword=dxPassword1234 --host=${var.vpnserver_hostname}.adsadadscom",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for client config ...'",
      "while [ ! -f /etc/openvpn/client.ovpn ]; do sleep 5; done",
      "echo 'DONE!'",
    ]

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "${var.vpnserver_username}"
      private_key = "${file(var.ssh_private_key_file)}"
      timeout     = "5m"
    }
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ${var.ssh_private_key_file} ${var.vpnserver_username}@${azurerm_public_ip.PublicIP.ip_address}:/etc/openvpn/client.ovpn ${var.client_config_path}/${var.client_config_name}.ovpn"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Scheduling instance reboot in one minute ...'",
      "sudo shutdown -r +1",
    ]

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "${var.vpnserver_username}"
      private_key = "${file(var.ssh_private_key_file)}"
      timeout     = "5m"
    }
  }

  provisioner "local-exec" {
    command = "rm -f ${var.client_config_path}/${var.client_config_name}.ovpn"
    when    = "destroy"
  }
}

# Template for shell script ./scripts/openvpn.sh
data "template_file" "deployment_shell_script" {
  template = "${file(var.build_vpnserver)}"

  vars {
    cert_details       = "${file(var.cert_details)}"
    client_config_name = "${var.client_config_name}"
  }
}


