# If we have this file with the main there is no need to declare this here
# Configure the Microsoft Azure Provider.
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }  
}

# We will be using Azure CLI to connect
# to change it there is a template code on the relevant webpage (Hashicorp website)
provider "azurerm" {
  features {}
  
#   subscription_id = ""
#   client_id       = ""
#   client_secret   = ""
#   tenant_id       = ""
}

#end of configuration for the Microsoft Azure Provider

#!!! Create resource group
resource "azurerm_resource_group" "main_vm02" {
  name     = "${var.prefix}-Group-${var.vmname}"
  location = var.location
}

#=================================START OF NETWORKING SECTION=============================

#Create the virtual network
resource "azurerm_virtual_network" "main_vm02" {
  name                = "${var.prefix}-VirtualNetwork-${var.vmname}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main_vm02.name
}

#Configure Network security group
resource "azurerm_network_security_group" "main_vm02" {
  name                = "${var.prefix}-NetSecurityGroup-${var.vmname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main_vm02.name

    #Rule to allow SSH connections
    security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

#     #Rule to publish port 8080 for Application
    security_rule {
    name                       = "ApplicationPort"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "${var.prefix}-${var.vmname}"
  }
}

#Configure the Private IP Address for the Virtual Machine
resource "azurerm_subnet" "internal" {
  name                 = "internal-${var.vmname}"
  resource_group_name  = azurerm_resource_group.main_vm02.name
  virtual_network_name = azurerm_virtual_network.main_vm02.name
  address_prefixes     = ["10.0.2.0/24"]
}
#=============================END OF NET CONFIGURATION=====================

#Configure the Public IP Address for the Virtual Machine
resource "azurerm_public_ip" "public_ip_vm02" {
  name                = "${var.prefix}-public_ip-${var.vmname}"
  resource_group_name = azurerm_resource_group.main_vm02.name
  location            = var.location
  #Static allocation is required to retrieve the IP for the remote-exec provisioner
  allocation_method   = "Static" 
}
#=============================END OF PUBLIC IP ADDRESS CONFIGURATION======================

#Configure the Network interface and assign both private and public ip
resource "azurerm_network_interface" "main_vm02" {
  name                = "${var.prefix}-nic-${var.vmname}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main_vm02.name

  ip_configuration {
    name                          = "${var.prefix}-IPConfig-${var.vmname}"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    #this line is required to assign the public IP address for the VM
    public_ip_address_id          = azurerm_public_ip.public_ip_vm02.id
  }
}
#=============================END OF NETWORK INTERFACE CONFIGURATION======================

#=========================================================================================
#===================================END OF NETWORKING SECTION=============================

#VIRTUAL MACHINE / OS DISK
resource "azurerm_virtual_machine" "main_vm02" {
  name                  = "${var.prefix}-${var.vmname}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main_vm02.name
  network_interface_ids = [azurerm_network_interface.main_vm02.id]
  vm_size               = "Standard_B1s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    #publisher = "Canonical"
    #offer     = "UbuntuServer"
    #sku       = "20.04-LTS"
    #version   = "latest"

    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "20.04.202010140"

  }
  storage_os_disk {
    name              = "${var.prefix}-${var.vmname}_Disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "host-${var.vmname}"
    admin_username = var.username
    admin_password = var.password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "${var.prefix}-${var.vmname}"
  }

#Run a command on the local machine to create a file containing the public IP
#address of the newly crated VM
#This is the version for both Linux and Windows
provisioner "local-exec" {
  command = "echo ${azurerm_public_ip.public_ip_vm02.ip_address} >> publicip${var.vmname}.txt"  
}

}
