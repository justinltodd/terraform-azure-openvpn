# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "36483a93-0c29-4b4f-89fd-2b1077a44280"
  client_id       = "29e008e2-2708-4484-9e78-9a652389124b"
  client_secret   = "Mi2@/mM=4Js3l4xRv:KrCEjHlvGU]N@3"
  tenant_id       = "8ce308d8-142f-4ba1-8e44-7ac446b0b300"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "terraform_pacman_rgroup_jtodd" {
  name     = "terraform_pacman_test"
  location = "centralus"

  tags = {
    environment = "Terraform Pacman Demo"
  }

}

# Create virtual network
resource "azurerm_virtual_network" "terraform_pacman_network_jtodd" {
  name                = "terraform_pacman_test_Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "centralus"
  resource_group_name = "${azurerm_resource_group.terraform_pacman_rgroup_jtodd.name}"

  tags = {
    environment = "Terraform Pacman Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "terraform_pacman_subnet_jtodd" {
  name                 = "terraform_pacman_test_subnet"
  resource_group_name  = "${azurerm_resource_group.terraform_pacman_rgroup_jtodd.name}"
  virtual_network_name = "${azurerm_virtual_network.terraform_pacman_network_jtodd.name}"
  address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "terraform_pacman_publicip_jtodd" {
  name                = "terraform_pacman_test_publicIP"
  location            = "centralus"
  resource_group_name = "${azurerm_resource_group.terraform_pacman_rgroup_jtodd.name}"
  allocation_method   = "Dynamic"

  tags = {
    environment = "Terraform Pacman Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "terraform_pacman_jtodd-sg" {
  name                = "terraform_pacman-SecurityGroup-jtodd"
  location            = "centralus"
  resource_group_name = "${azurerm_resource_group.terraform_pacman_rgroup_jtodd.name}"

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
    environment = "Terraform Pacman Demo"
  }
}

# Create network interface
resource "azurerm_network_interface" "terraform_pacman_jtodd-nic" {
  name                      = "terraform_pacman_NIC"
  location                  = "centralus"
  resource_group_name       = "${azurerm_resource_group.terraform_pacman_rgroup_jtodd.name}"
  network_security_group_id = "${azurerm_network_security_group.terraform_pacman_jtodd-sg.id}"

  ip_configuration {
    name                          = "terraform_pacman_NicConfiguration"
    subnet_id                     = "${azurerm_subnet.terraform_pacman_subnet_jtodd.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.terraform_pacman_publicip_jtodd.id}"
  }

  tags = {
    environment = "Terraform Pacman Demo"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.terraform_pacman_rgroup_jtodd.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "terraform_pacman_test_storage" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.terraform_pacman_rgroup_jtodd.name}"
  location                 = "centralus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Terraform Pacman Demo"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "terraform_pacman_test_vm" {
  name                  = "pacman_demo01"
  location              = "centralus"
  resource_group_name   = "${azurerm_resource_group.terraform_pacman_rgroup_jtodd.name}"
  network_interface_ids = ["${azurerm_network_interface.terraform_pacman_jtodd-nic.id}"]
  vm_size               = "Standard_B2ms"

  storage_os_disk {
    name              = "disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    os_type           = "Windows"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "19h1-pro"
    version   = "18362.418.1910070306"
  }

  os_profile {
    computer_name  = "pacman-Win10demo01"
    admin_username = "pacman"
    admin_password = "pasword1234"
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true
    provision_vm_agent        = true
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.terraform_pacman_test_storage.primary_blob_endpoint}"
  }

  tags = {
    environment = "Terraform Pacman Demo"
    CreatedBy   = "JTODD",
    Purpose     = "Windows Automation Client"
  }


  #--- Post Install Provisioning ---

}
