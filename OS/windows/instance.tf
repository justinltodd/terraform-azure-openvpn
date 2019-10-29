# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "terraform_pacman_rgroup" {
  name     = "terraform_pacman_demo"
  location = "centralus"

  tags = {
    environment = "Terraform Pacman Demo"
  }

}

# Create virtual network
resource "azurerm_virtual_network" "terraform_pacman_network" {
  name                = "terraform_pacman_Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "centralus"
  resource_group_name = "${azurerm_resource_group.terraform_pacman_rgroup.name}"

  tags = {
    environment = "Terraform Pacman Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "terraform_pacman_subnet" {
  name                 = "subnet0"
  resource_group_name  = "${azurerm_resource_group.terraform_pacman_rgroup.name}"
  virtual_network_name = "${azurerm_virtual_network.terraform_pacman_network.name}"
  address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "terraform_pacman_PublicIP" {
  name                = "PublicIP"
  location            = "centralus"
  resource_group_name = "${azurerm_resource_group.terraform_pacman_rgroup.name}"
  allocation_method   = "Dynamic"

  tags = {
    environment = "Terraform Pacman Demo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "terraform_pacman-NSG" {
  name                = "Pacman-SecurityGroup"
  location            = "centralus"
  resource_group_name = "${azurerm_resource_group.terraform_pacman_rgroup.name}"

  security_rule { //Here opened remote desktop port
    name                       = "RDP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule { //Here opened WinRMport
    name                       = "WinRM"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule { //Here opened https port for outbound
    name                       = "WinRM-out"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule { //Here opened https port
    name                       = "HTTPS"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  #  security_rule { //BluePrism API Port
  #    name                       = "BluePrismAPI"
  #    priority                   = 8181
  #    direction                  = "Inbound"
  #    access                     = "Allow"
  #    protocol                   = "Tcp"
  #    source_port_range          = "*"
  #    destination_port_range     = "443"
  #    source_address_prefix      = "*"
  #    destination_address_prefix = "*"
  #  }

  #  security_rule { //BluePrism API Port
  #    name                       = "BluePrismAPI"
  #    priority                   = 8181
  #    direction                  = "Outbound"
  #    access                     = "Allow"
  #    protocol                   = "Tcp"
  #    source_port_range          = "*"
  #    destination_port_range     = "443"
  #    source_address_prefix      = "*"
  #    destination_address_prefix = "*"
  #  }

  tags = {
    environment = "Terraform Pacman Demo"
  }
}

# Create network interface
resource "azurerm_network_interface" "terraform_pacman-WindowsNic" {
  name                      = "primaryNic01"
  location                  = "centralus"
  resource_group_name       = "${azurerm_resource_group.terraform_pacman_rgroup.name}"
  network_security_group_id = "${azurerm_network_security_group.terraform_pacman-NSG.id}"

  ip_configuration {
    name                          = "ipconfig01"
    subnet_id                     = "${azurerm_subnet.terraform_pacman_subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.terraform_pacman_PublicIP.id}"
  }

  tags = {
    environment = "Terraform Pacman Demo"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.terraform_pacman_rgroup.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "terraform_pacman_test_storage" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.terraform_pacman_rgroup.name}"
  location                 = "centralus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Terraform Pacman Demo"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "pacman" {
  name                  = "pacman"
  location              = "centralus"
  resource_group_name   = "${azurerm_resource_group.terraform_pacman_rgroup.name}"
  network_interface_ids = ["${azurerm_network_interface.terraform_pacman-WindowsNic.id}"]
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
    computer_name  = "pacman01"
    admin_username = "pacman"
    admin_password = "Pasword1234"
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