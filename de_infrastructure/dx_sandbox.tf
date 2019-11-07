# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.dx01.name}"
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "terraform_dx01_windows10_storage" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.dx01.name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Windows 10 Desktop: ${var.windows_hostname}"
  }
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "terraform_dx01_test_storage" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = "${azurerm_resource_group.terraform_dx01_rgroup.name}"
  location                 = "centralus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Windows 10 Desktop: ${var.windows_hostname}"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "dx01" {
  name                  = "dx01"
  location              = "centralus"
  resource_group_name   = "${azurerm_resource_group.terraform_dx01_rgroup.name}"
  network_interface_ids = ["${azurerm_network_interface.terraform_dx01-WindowsNic.id}"]
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
    computer_name  = "dx01"
    admin_username = "admin"
    admin_password = "Pasword1234"
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true
    provision_vm_agent        = true
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.terraform_dx01_test_storage.primary_blob_endpoint}"
  }

  tags = {
    environment = "Terraform dx01 Demo"
    CreatedBy   = "JTODD",
    Purpose     = "Windows Automation Client"
  }


  #--- Post Install Provisioning ---

}

