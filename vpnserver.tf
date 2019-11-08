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

  # Install Openvpn and other required binarys
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get -y upgrade",
      "sudo apt-get -y install curl wget",
      "curl -s https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -",
      "echo 'deb http://build.openvpn.net/debian/openvpn/stable bionic main' > /etc/apt/sources.list.d/openvpn-aptrepo.list",
      "sudo apt-get update",
      "sudo apt-get -y install gcc",
      "sudo apt-get -y install make",
      "sudo apt-get -y install lighttpd",
      "sudo apt-get -y install openvpn",
      "sudo apt-get -y install ca-certificates",
      "sudo apt-get -y install openssl",
    ]
  }

  # Install Latest verions of EasyRSA and setup CA Authority
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo curl -s https://api.github.com/repos/OpenVPN/easy-rsa/releases/latest | grep 'browser_download_url.*tgz' | cut -d : -f 2,3 | tr -d '$\"' | awk '!/sig/' | wget -O /tmp/EasyRSA.tgz -qi -",
      "sudotar -zxvf /tmp/EasyRSA.tgz --one-top-level=/etc/openvpn/easy-rsa",
      "sudo tar -zxvf /tmp/EasyRSA.tgz --transform 's/EasyRSA-v3.0.6/easy-rsa/' --one-top-level=/etc/openvpn/",
      "sudo chown -R root:root /etc/openvpn/easy-rsa/",
      "sudo rm -rf /tmp/EasyRSA.tgz",
      "cd /etc/openvpn/easy-rsa/",
      "sudo ./easyrsa init-pki",
      "sudo ./easyrsa --batch build-ca nopass",
      "sudo ./easyrsa gen-dh",
      "sudo ./easyrsa build-server-full server nopass,"
      "sudo ./easyrsa gen-crl",
      "sudo cp pki/ca.crt pki/private/ca.key pki/dh.pem pki/issued/server.crt pki/private/server.key /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn",
      "sudo chown nobody:nogroup /etc/openvpn/crl.pem",
      "sudo openvpn --genkey --secret /etc/openvpn/ta.key",
    ]
  }

  provisioner "file" {
    source     = "${var.dh_pem}"
    destination = "/etc/openvpn/server/dh.pem"
  }

  provisioner "file" {
    content     = "${var.build_vpnserver}"
    destination = "/tmp/openvpn.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/openvpn.sh",
      "sudo /tmp/openvpn.sh --adminpassword=dxPassword1234 --host=${var.vpnserver_hostname}.centralus.cloudapp.azure.com",
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


