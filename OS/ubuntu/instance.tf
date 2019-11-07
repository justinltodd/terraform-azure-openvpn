# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "terraform_dx01_rgroup" {
  name     = "terraform_dx01_test"
  location = "centralus"

  tags = {
    environment = "Terraform dx01 Demo"
  }

}

# Create virtual network
resource "azurerm_virtual_network" "terraform_dx01_network" {
  name                = "terraform_dx01_test_Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "centralus"
  resource_group_name = "${azurerm_resource_group.terraform_dx01_rgroup.name}"

  tags = {
    environment = "Terraform dx01 Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "terraform_dx01_subnet" {
  name                 = "terraform_dx01_test_subnet"
  resource_group_name  = "${azurerm_resource_group.terraform_dx01_rgroup.name}"
  virtual_network_name = "${azurerm_virtual_network.terraform_dx01_network.name}"
  address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "terraform_dx01_PublicIP" {
  name                = "PublicIP"
  location            = "centralus"
  resource_group_name = "${azurerm_resource_group.terraform_dx01_rgroup.name}"
  allocation_method   = "Dynamic"

  tags = {
    environment = "Terraform dx01 Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "terraform_dx01-NSG" {
  name                = "dx01-SecurityGroup"
  location            = "centralus"
  resource_group_name = "${azurerm_resource_group.terraform_dx01_rgroup.name}"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Terraform dx01 Demo"
  }
}

# Create network interface
resource "azurerm_network_interface" "terraform_dx01-UbuntuNic" {
  name                      = "primaryNic01"
  location                  = "centralus"
  resource_group_name       = "${azurerm_resource_group.terraform_dx01_rgroup.name}"
  network_security_group_id = "${azurerm_network_security_group.terraform_dx01-NSG.id}"

  ip_configuration {
    name                          = "ethernet01"
    subnet_id                     = "${azurerm_subnet.terraform_dx01_subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.terraform_dx01_PublicIP.id}"
  }

  tags = {
    environment = "Terraform dx01 Demo"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.terraform_dx01_rgroup.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "terraform_dx01_test_storage" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.terraform_dx01_rgroup.name}"
  location                 = "centralus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Terraform dx01 Demo"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "dx01" {
  name                  = "dx01"
  location              = "centralus"
  resource_group_name   = "${azurerm_resource_group.terraform_dx01_rgroup.name}"
  network_interface_ids = ["${azurerm_network_interface.terraform_dx01-UbuntuNic.id}"]
  vm_size               = "Standard_B2ms"

  storage_os_disk {
    name              = "disk1"
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
    computer_name  = "dx0101"
    admin_username = "dx01"
    admin_password = "Pasword1234"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/dx01/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC74HfO/rCZ2HxvE2vEtUsDpLg7tjPWKPr/kk2qf03KBSyUg7sAdajawv0JRz+sfl8NiOJ69q/kpUGBuVUTDB58zyF9X4OCR7OQCn5B7wOG96nxMZbbPjQhkGZlz9XfQBfF8eCsA5fZDe62ZswLyOWgtPuMKK722n8BT9llwojZwZsEFga00d/JJM0w9ePsoDzF2j2/AWLsCief+WwnJsRz+1CqY3R4La8/k6NHCTAeXyQpfJg6Sc4dy8Bstc6ck27ExqW0pNv+MI5FuaDTYPvdKpYbQHk/T1qvX6/nU5QAwLKmHWr3nO9TRymaUlLApQP0410vFnpI5zt84eR/5o8t justintodd@pokerspro.localdomain"
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.terraform_dx01_test_storage.primary_blob_endpoint}"
  }

  tags = {
    environment = "Terraform dx01 Demo"
  }
}
