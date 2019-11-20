# Template for shell script ./scripts/server.conf.template
data "template_file" "vpn_server_configuration_file" {
  template = "${file("${var.server_conf}")}"

  vars = {
    VPN_PORT           = "${var.VPN_PORT}"
    VPN_PROTOCOL       = "${var.VPN_PROTOCOL}"
    VPN_CLIENT_CIDR    = "${var.VPN_CLIENT["CIDR"]}"
    VPN_CLIENT_SUBNET  = "${var.VPN_CLIENT["SUBNET"]}"
    VPN_CLIENT_NETMASK = "${var.VPN_CLIENT["NETMASK"]}"
    VPN_HUB_SUBNET     = "${var.VPN_HUB["SUBNET"]}"
    VPN_HUB_NETMASK    = "${var.VPN_HUB["NETMASK"]}"
    VPN_DNS1           = "${var.VPN_DNS1}"
    VPN_DNS2           = "${var.VPN_DNS2}"
    LOCATION           = "${var.location}"
    VPN_HOST           = "${var.vpnserver_hostname}"
    VPN_PRIVATE_IP     = "${var.VPN_PRIVATE_IP}"
    VPN_DOMAIN         = "${var.DOMAIN["VPNSERVER"]}.${var.DOMAIN["LOCATION"]}.${var.DOMAIN["ZONE"]}"
    VPN_COMPRESSION    = "${var.VPN_COMPRESSION}"
  }
}

# Template for shell script ./scripts/client.conf.template
data "template_file" "vpn_client_template_file" {
  template = "${file("${var.client_template}")}"

  vars = {
    VPN_PORT           = "${var.VPN_PORT}"
    VPN_PROTOCOL       = "${var.VPN_PROTOCOL}"
    VPN_CLIENT_CIDR    = "${var.VPN_CLIENT["CIDR"]}"
    VPN_CLIENT_SUBNET  = "${var.VPN_CLIENT["SUBNET"]}"
    VPN_CLIENT_NETMASK = "${var.VPN_CLIENT["NETMASK"]}"
    VPN_HUB_SUBNET     = "${var.VPN_HUB["SUBNET"]}"
    VPN_HUB_NETMASK    = "${var.VPN_HUB["NETMASK"]}"
    VPN_DNS1           = "${var.VPN_DNS1}"
    VPN_DNS2           = "${var.VPN_DNS2}"
    LOCATION           = "${var.location}"
    VPN_HOST           = "${var.vpnserver_hostname}"
    VPN_PRIVATE_IP     = "${var.VPN_PRIVATE_IP}"
    VPN_DOMAIN         = "${var.DOMAIN["VPNSERVER"]}.${var.DOMAIN["LOCATION"]}.${var.DOMAIN["ZONE"]}"
    VPN_COMPRESSION    = "${var.VPN_COMPRESSION}"
  }
}

# Template for shell script ./scripts/lighttpd.conf.template
data "template_file" "lighttpd_template_file" {
  template = "${file("${var.lighttpd_template}")}"

  vars = {
    HOST     = "${var.vpnserver_hostname}"
    LOCATION = "${var.location}"
    ADMIN    = "${var.vpnserver_username}"
    PASS     = "${var.vpnserver_password}"
  }
}

# Template for shell script ./scripts/lighttpd.conf.template
data "template_file" "networking_template_file" {
  template = "${file("${var.networking_template}")}"

  vars = {
    VPN_CLIENT_CIDR    = "${var.VPN_CLIENT["CIDR"]}"
    VPN_CLIENT_SUBNET  = "${var.VPN_CLIENT["SUBNET"]}"
    VPN_CLIENT_NETMASK = "${var.VPN_CLIENT["NETMASK"]}"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "vpn_randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "dx_vpn_storage" {
  name                     = "diag${random_id.vpn_randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  location                 = "${azurerm_resource_group.vpn_hub_vnet-rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "vpnserver: ${var.vpnserver_hostname}"
  }
}

# Create openvpn virtual machine
resource "azurerm_virtual_machine" "openvpn" {
  name                  = "${var.vpnserver_hostname}"
  location              = "${azurerm_resource_group.vpn_hub_vnet-rg.location}"
  resource_group_name   = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.vpnserver_nic.id}"]
  vm_size               = "${var.vpnserver_vmsize}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

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

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.dx_vpn_storage.primary_blob_endpoint}"
  }

  tags = {
    environment = "VPN Server: ${var.vpnserver_hostname}"
  }

  # Allow root ssh access with key
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.$$",
      "sudo cp ~/.ssh/authorized_keys /root/.ssh/authorized_keys",
    ]

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "${var.vpnserver_username}"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  # Install Openvpn and other required binarys
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get -y upgrade",
      "sudo apt-get -y autoremove",
      "sudo apt-get -y install curl wget",
      "sudo add-apt-repository universe",
      "sudo add-apt-repository -y ppa:certbot/certbot",
      "sudo curl -s https://swupdate.openvpn.net/repos/repo-public.gpg | apt-key add -",
      "echo 'deb http://build.openvpn.net/debian/openvpn/stable bionic main' > /etc/apt/sources.list.d/openvpn-aptrepo.list",
      "sudo apt-get update",
      "sudo apt-get -y install gcc software-properties-common",
      "sudo apt-get -y install make",
      "sudo apt-get -y install lighttpd",
      "sudo apt-get -y install openvpn",
      "sudo apt-get -y install ca-certificates",
      "sudo apt-get -y install openssl",
      "sudo apt-get -y install certbot",
    ]

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  # Provision dh.pem - Create the DH parameters file using the predefined ffdhe2048 group
  provisioner "file" {
    source      = "${var.dh_pem}"
    destination = "/etc/openvpn/server/dh4096.pem"

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  # Render the vars file for easy-rsa CA creation
  provisioner "file" {
    source      = "./scripts/vars"
    destination = "/tmp/vars"

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  # Install Latest verions of EasyRSA and setup CA Authority
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo mv /etc/openvpn/easy-rsa/ /etc/openvpn/easy-rsa.$$.old 2> /dev/null", #//If old easy-rsa exists then it will move to backup dir. 
      "sudo curl -s https://api.github.com/repos/OpenVPN/easy-rsa/releases/latest | grep 'browser_download_url.*tgz' | cut -d : -f 2,3 | tr -d '$\"' | awk '!/sig/' | wget -O /tmp/EasyRSA.tgz -qi -",
      "sudo tar -zxvf /tmp/EasyRSA.tgz --transform 's/EasyRSA-v3.0.6/easy-rsa/' --one-top-level=/etc/openvpn/",
      "sudo chown -R root:root /etc/openvpn/easy-rsa/",
      "sudo rm -rf /tmp/EasyRSA.tgz",
      "sudo mv /tmp/vars /etc/openvpn/easy-rsa",
      "cd /etc/openvpn/easy-rsa/",
      "sudo ./easyrsa init-pki",
      "sudo touch /etc/openvpn/easy-rsa/pki/.rnd",
      "sudo ./easyrsa --batch --req-cn=${var.vpnserver_hostname}-RootCA build-ca nopass",
      "sudo ./easyrsa build-server-full ${var.vpnserver_hostname} nopass",
      "sudo ./easyrsa gen-crl",
      "sudo cp pki/ca.crt pki/private/ca.key pki/issued/${var.vpnserver_hostname}.crt pki/private/${var.vpnserver_hostname}.key /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/server/",
      "sudo chown nobody:nogroup /etc/openvpn/server/crl.pem",
      "sudo openvpn --genkey --secret /etc/openvpn/server/ta.key",
    ]

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  # Script for network adjustments such as IP forwarding.
  provisioner "file" {
    content     = "${data.template_file.networking_template_file.rendered}"
    destination = "/tmp/networking.sh"

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  ## Enable net.ipv4.ip_forward for the system and ## Firewall UFW Settings 
  provisioner "remote-exec" {
    inline = [
      "sleep 15",
      "sudo chmod 775 /tmp/networking.sh",
      "sudo /tmp/networking.sh",
      #"sudo rm -rf /tmp/networking.sh",
    ]

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  ## Adjust permissions for openvpn to be available via HTTPS 
  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "sudo rm /var/www/html/*",
      "sudo mkdir /etc/openvpn/clients/",
      "sudo chown -R www-data:www-data /etc/openvpn/easy-rsa",
      "sudo chown -R www-data:www-data /etc/openvpn/clients/",
      "sudo chmod -R 755 /etc/openvpn/",
      "sudo chmod -R 777 /etc/openvpn/server/crl.pem",
      "sudo chmod g+s /etc/openvpn/clients/",
      "sudo chmod g+s /etc/openvpn/easy-rsa/",
    ]

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  # Setup script for lighttpd client website
  provisioner "file" {
    source      = "./scripts/index.sh"
    destination = "/var/www/html/index.sh"

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  # Setup script for lighttpd client website
  provisioner "file" {
    source      = "./scripts/download.sh"
    destination = "/var/www/html/download.sh"

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  ## LetsEncrypt SSL cert for Lighttpd
  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "sudo service lighttpd stop",
      "sudo certbot certonly --standalone -n -d ${var.vpnserver_hostname}.${var.location}.cloudapp.azure.com --email noreply@blueprism.com --agree-tos --redirect --hsts",
      "sudo cat /etc/letsencrypt/live/${var.vpnserver_hostname}.${var.location}.cloudapp.azure.com/privkey.pem /etc/letsencrypt/live/${var.vpnserver_hostname}.${var.location}.cloudapp.azure.com/cert.pem > /etc/letsencrypt/live/${var.vpnserver_hostname}.${var.location}.cloudapp.azure.com/combined.pem",
      "sudo chown -R www-data:www-data /var/www/html/",
      "sudo mv /etc/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf.$$",
      "sudo echo '${var.vpnserver_username}:${var.vpnserver_password}' >> /etc/lighttpd/.lighttpdpassword",
      "sudo chmod g+x /etc/letsencrypt",
      "sudo chmod g+x /etc/letsencrypt/live",
    ]

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  # Render the server.conf.template template file -> server.conf
  provisioner "file" {
    content     = "${data.template_file.vpn_server_configuration_file.rendered}"
    destination = "/etc/openvpn/server/server.conf"

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  # Render the lient.conf.template template file
  provisioner "file" {
    content     = "${data.template_file.vpn_client_template_file.rendered}"
    destination = "/etc/openvpn/client.conf.template"

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  # Render the lighttpd.conf template file
  provisioner "file" {
    content     = "${data.template_file.lighttpd_template_file.rendered}"
    destination = "/etc/lighttpd/lighttpd.conf"

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  ## Enable openvpn and lighttpd server and restart service 
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl start openvpn-server@server.service",
      "sudo systemctl restart lighttpd.service",
      "sudo systemctl enable openvpn-server@server.service",
      "sudo systemctl enable lighttpd.service",
    ]

    connection {
      host        = "${azurerm_public_ip.PublicIP.ip_address}"
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.ssh_private_key_file}")}"
      timeout     = "5m"
    }
  }

  ## Reboot vpnserver (optional)
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
}

# VPNSERVER PublicIP
resource "azurerm_public_ip" "PublicIP" {
  name                = "${var.vpnserver_hostname}-public"
  resource_group_name = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  location            = "${azurerm_resource_group.vpn_hub_vnet-rg.location}"
  allocation_method   = "Static"
  domain_name_label   = "${var.vpnserver_hostname}" #//adds dns using hostname.centralus.cloudapp.azure.com

  tags = {
    environment = "VPN Server: ${var.vpnserver_hostname}"
  }
}

# VPNSERVER Network Interface
resource "azurerm_network_interface" "vpnserver_nic" {
  name                      = "${var.vpnserver_nic}"
  location                  = "${azurerm_resource_group.vpn_hub_vnet-rg.location}"
  resource_group_name       = "${azurerm_resource_group.vpn_hub_vnet-rg.name}"
  network_security_group_id = "${azurerm_network_security_group.vpn-sg.id}"
  enable_ip_forwarding      = true


  ip_configuration {
    name                          = "${var.vpnserver_hostname}"
    subnet_id                     = "${azurerm_subnet.vpn_hub_subnet.id}"
    private_ip_address_allocation = "Dynamic"
    #private_ip_address           = "${var.VPN_PRIVATE_IP}"
    public_ip_address_id = "${azurerm_public_ip.PublicIP.id}"
  }

  tags = {
    environment = "VPN Server Hostname: ${var.vpnserver_hostname}"
  }
}

