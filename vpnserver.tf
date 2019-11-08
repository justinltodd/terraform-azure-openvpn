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
      "sudo add-apt-repository universe",
      "sudo add-apt-repository -y ppa:certbot/certbot",
      "curl -s https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -",
      "echo 'deb http://build.openvpn.net/debian/openvpn/stable bionic main' > /etc/apt/sources.list.d/openvpn-aptrepo.list",
      "sudo apt-get update",
      "sudo apt-get -y install gcc software-properties-common",
      "sudo apt-get -y install make",
      "sudo apt-get -y install lighttpd",
      "sudo apt-get -y install openvpn",
      "sudo apt-get -y install ca-certificates",
      "sudo apt-get -y install openssl",
      "sudo apt-get -y install certbot",
      "systemctl enable openvpn@server.servic.service",
      "systemctl restart openvpn@server.service",
    ]
  }

  # Install Latest verions of EasyRSA and setup CA Authority
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "if [[ -d /etc/openvpn/easy-rsa/ ]]; then sudo rm -rf /etc/openvpn/easy-rsa/; fi",
      "sudo curl -s https://api.github.com/repos/OpenVPN/easy-rsa/releases/latest | grep 'browser_download_url.*tgz' | cut -d : -f 2,3 | tr -d '$\"' | awk '!/sig/' | wget -O /tmp/EasyRSA.tgz -qi -",
      "sudo tar -zxvf /tmp/EasyRSA.tgz --one-top-level=/etc/openvpn/easy-rsa",
      "sudo tar -zxvf /tmp/EasyRSA.tgz --transform 's/EasyRSA-v3.0.6/easy-rsa/' --one-top-level=/etc/openvpn/",
      "sudo chown -R root:root /etc/openvpn/easy-rsa/",
      "sudo rm -rf /tmp/EasyRSA.tgz",
      "cd /etc/openvpn/easy-rsa/",
      "sudo ./easyrsa init-pki",
      "sudo ./easyrsa --batch build-ca nopass",
      "EASYRSA_CERT_EXPIRE=3650 sudo ./easyrsa build-server-full server nopass",
      "EASYRSA_CRL_DAYS=3650 sudo ./easyrsa gen-crl",
      "sudo cp pki/ca.crt pki/private/ca.key pki/dh.pem pki/issued/server.crt pki/private/server.key /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn",
      "sudo chown nobody:nogroup /etc/openvpn/crl.pem",
      "sudo openvpn --genkey --secret /etc/openvpn/ta.key",
    ]
  }

  ## Get IP address and add it to server.conf
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "IP=$(ip addr | grep inet | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'| head -1) | echo 'local' $IP >> /etc/openvpn/server/server.conf",
    ]
  }

  ## Enable net.ipv4.ip_forward for the system
  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "sudo sed -i '/\<net.ipv4.ip_forward\>/c\net.ipv4.ip_forward=1' /etc/sysctl.conf",
      "if ! grep -q '\<net.ipv4.ip_forward\>' /etc/sysctl.conf; then sudo echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf; fi",
      "sudo echo 1 > /proc/sys/net/ipv4/ip_forward",
    ]
  }

  ## Adjust permissions for openvpn to be available via HTTPS 
  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "sudo rm /var/www/html/*",
      "sudo mkdir /etc/openvpn/clients/",
      "chown -R www-data:www-data /etc/openvpn/easy-rsa",
      "chown -R www-data:www-data /etc/openvpn/clients/",
      "chmod -R 755 /etc/openvpn/",
      "chmod -R 777 /etc/openvpn/crl.pem",
      "chmod g+s /etc/openvpn/clients/",
      "chmod g+s /etc/openvpn/easy-rsa/",
    ]
  }

    # Setup script for lighttpd client website
  provisioner "file" {
    source     = "./scripts/index.sh"
    destination = "/var/www/html/index.sh"
  }

  # Setup script for lighttpd client website
  provisioner "file" {
    source     = "./scripts/download.sh"
    destination = "/var/www/html/download.sh"
  }

  ## LetsEncrypt SSL cert for Lighttpd
  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "sudo service lighttpd stop",
      "sudo certbot certonly --standalone -n -d ${var.vpnserver_hostname}.${var.location}.cloudapp.azure.com --email noreply@blueprism.com --agree-tos --redirect --hsts",
      "cat /etc/letsencrypt/live/${var.vpnserver_hostname}.${var.location}.cloudapp.azure.com/privkey.pem /etc/letsencrypt/live/${var.vpnserver_hostname}.${var.location}.cloudapp.azure.com/cert.pem > /etc/letsencrypt/live/${var.vpnserver_hostname}.${var.location}.cloudapp.azure.com/combined.pem",
      "sudo chown -R www-data:www-data /var/www/html/",
      "sudo mv /etc/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf.$$",
      "sudo echo '${var.vpnserver_username}:${var.vpnserver_password}' >> /etc/lighttpd/.lighttpdpassword",
      "sudo chown :lighttpd /etc/letsencrypt",
      "sudo chown :lighttpd /etc/letsencrypt/live",
      "sudo chmod g+x /etc/letsencrypt",
      "sduo chmod g+x /etc/letsencrypt/live",
    ]
  }

  # Provision dh.pem - Create the DH parameters file using the predefined ffdhe2048 group
  provisioner "file" {
    source     = "${var.dh_pem}"
    destination = "/etc/openvpn/server/dh.pem"
  }

  # Render the server.conf template file
  provisioner "file" {
    content     = "${data.template_file.vpn_server_configuration_file.rendered}"
    destination = "/etc/openvpn/server/server.conf"
  }

  # Render the client-common.txt template file
  provisioner "file" {
    content     = "${data.template_file.vpn_client_template_file.rendered}"
    destination = "/etc/openvpn/client-common.txt"
  }

  # Render the lighttpd.conf template file
  provisioner "file" {
    content     = "${data.template_file.lighttpd_template_file.rendered}"
    destination = "/etc/lighttpd/lighttpd.conf"
  }

  ## Enable openvpn Service and restart service 
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart openvpn@server.service",
      "sudo systemctl restart lighttpd.service",
      "sudo systemctl enable openvpn@server.service",
      "sudo systemctl enable lighttpd.service",
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
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ${var.ssh_private_key_file} ${var.vpnserver_username}@${var.VPNSERVER_IP}:/etc/openvpn/client.ovpn ${var.client_config_path}/${var.client_config_name}.ovpn"
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
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  provisioner "local-exec" {
    command = "rm -f ${var.client_config_path}/${var.client_config_name}.ovpn"
    when    = "destroy"
  }

# Template for shell script ./scripts/openvpn.sh
data "template_file" "deployment_shell_script" {
  template = "${file("${var.build_vpnserver}")}"

  vars {
    cert_details       = "${file(var.cert_details)}"
    client_config_name = "${var.client_config_name}"
  }
}

# Template for shell script ./scripts/server.conf
data "template_file" "vpn_server_configuration_file" {
  template = "${file("${var.server_conf}")}"

  vars {
    PORT              = "${var.PORT}"
    PROTOCOL          = "${var.PROTOCOL}"
    VPN_IP            = "${var.VPN_IP}"
    VPNSERVER_Subnet  = "${var.VPNSERVER_Subnet}"
    DNS1              = "${var.DNS1}"
    DNS2              = "${var.DNS2}"
    LOCATION          = "${var.location}"
  }
}

# Template for shell script ./scripts/client-common.txt
data "template_file" "vpn_client_template_file" {
  template = "${file("${var.client_template}")}"

  vars {
    PORT              = "${var.PORT}"
    PROTOCOL          = "${var.PROTOCOL}"
    VPN_IP            = "${var.VPN_IP}"
    VPNSERVER_Subnet  = "${var.VPNSERVER_Subnet}"
    DNS1              = "${var.DNS1}"
    DNS2              = "${var.DNS2}"
    HOST              = "${var.vpnserver_hostname}"
    LOCATION          = "${var.location}"
  }
}

# Template for shell script ./scripts/lighttpd.conf
data "template_file" "lighttpd_template_file" {
  template = "${file("${var.lighttpd_template}")}"

  vars {
    HOST              = "${var.vpnserver_hostname}"
    LOCATION          = "${var.location}"
  }
}
