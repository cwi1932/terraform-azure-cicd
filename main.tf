resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform"
  location = "East US 2"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-terraform"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-terraform"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# THIS WAS MISSING

resource "azurerm_network_interface" "nic" {

  name = "nic-terraform"

  location = azurerm_resource_group.rg.location

  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {

    name = "internal"

    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"

  }

}
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "azurerm_linux_virtual_machine" "vm" {

  name = "vm-terraform"

  resource_group_name = azurerm_resource_group.rg.name

  location = azurerm_resource_group.rg.location

  size = "Standard_D2s_v7"

  admin_username = "azureuser"
  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }


}

