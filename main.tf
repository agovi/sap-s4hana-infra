provider "azurerm" {
  version = "=2.10.0"
  features {}
}


resource "azurerm_resource_group" "sap-rg" {
name = var.rgname
location = var.location 
}

resource "azurerm_virtual_network" "sap-vnet" {
    name = "s4hana-poc-vnet"
    resource_group_name = azurerm_resource_group.sap-rg.name
    location = var.location
    address_space = [for num in var.vnetprefix:num]

}

resource "azurerm_subnet" "sap-app-subnet" {
    name = "sap-app-subnet"
    resource_group_name = azurerm_resource_group.sap-rg.name
    virtual_network_name = azurerm_virtual_network.sap-vnet.name
    address_prefixes = [var.sapappsubnet]
}

resource "azurerm_subnet" "sap-db-subnet" {
    name = "sap-db-subnet"
    resource_group_name = azurerm_resource_group.sap-rg.name
    virtual_network_name = azurerm_virtual_network.sap-vnet.name
    address_prefixes = [var.sapdbsubnet]
}


resource "azurerm_subnet" "bastion-subnet" {
    name = "AzureBastionSubnet"
    resource_group_name = azurerm_resource_group.sap-rg.name
    virtual_network_name = azurerm_virtual_network.sap-vnet.name
    address_prefixes = [var.bastionsubnet]
}

resource "azurerm_network_security_group" "sap-db-nsg" {
  name                = "SAPDatabaseNsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name

  security_rule {
    name                       = "HANAPortsfromApp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["30015","30013","50013"]
    source_address_prefix    = var.sapappsubnet
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "SSHfromBastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix    = var.bastionsubnet
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_security_group" "sap-app-nsg" {
  name                = "SAPApplicationNsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name

  security_rule {
    name                       = "RDPfromBastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix    = var.bastionsubnet
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_security_group" "bastion-nsg" {
  name                = "BastionNsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name

  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

   security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = ["22","3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

   security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
}

resource "azurerm_subnet_network_security_group_association" "sap-app-nsg-assc" {
  subnet_id                 = azurerm_subnet.sap-app-subnet.id
  network_security_group_id = azurerm_network_security_group.sap-app-nsg.id
}


resource "azurerm_subnet_network_security_group_association" "sap-db-nsg-assc" {
  subnet_id                 = azurerm_subnet.sap-db-subnet.id
  network_security_group_id = azurerm_network_security_group.sap-db-nsg.id
}


resource "azurerm_subnet_network_security_group_association" "bastion-nsg-assc" {
  subnet_id                 = azurerm_subnet.bastion-subnet.id
  network_security_group_id = azurerm_network_security_group.bastion-nsg.id
}


resource "azurerm_network_interface" "sapdb-nic" {
    name = join("-",[var.dbvmname,"nic"])
    location = var.location
    resource_group_name = azurerm_resource_group.sap-rg.name
    ip_configuration {
    name                          =  join("-",[var.dbvmname,"ipconfig01"])
    subnet_id                     =  azurerm_subnet.sap-db-subnet.id
    private_ip_address_allocation = "Dynamic"
    }
  enable_accelerated_networking = "true"
}

resource "azurerm_linux_virtual_machine" "sapdb-vm" {
  name                  =  var.dbvmname
  location              =  var.location
  resource_group_name   =  azurerm_resource_group.sap-rg.name
  size               =  var.dbvmsize
  admin_username =  "azureuser"
  network_interface_ids = [azurerm_network_interface.sapdb-nic.id]
  admin_password = var.adminpassword 
  disable_password_authentication = "false"

   os_disk {
    name              = join("-",[var.dbvmname,"osdisk"])
    caching           = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

 source_image_reference {
    publisher = "SUSE"
    offer = "SLES-SAP"
    sku = "12-SP4"
    version = "latest"
  }

}

resource "azurerm_managed_disk" "db-disks" {
  count  =  length(var.luns)
  name                 = join("-",[var.dbvmname,"datadisk",count.index])
  location             =  var.location
  resource_group_name  =  azurerm_resource_group.sap-rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.disksizes[count.index]
  
}

resource "azurerm_virtual_machine_data_disk_attachment" "db-disk-attach" {
  count = length(var.luns)
  managed_disk_id    =  azurerm_managed_disk.db-disks[count.index].id
  virtual_machine_id =  azurerm_linux_virtual_machine.sapdb-vm.id
  lun                =  var.luns[count.index]
  caching            =  var.cache_settings[count.index]
  write_accelerator_enabled = var.waflag[count.index]

}

resource "azurerm_network_interface" "sapapp-nic" {
    name = join("-",[var.appvmname,"nic"])
    location = var.location
    resource_group_name = azurerm_resource_group.sap-rg.name
    ip_configuration {
    name                          =  join("-",[var.appvmname,"ipconfig01"])
    subnet_id                     =  azurerm_subnet.sap-app-subnet.id
    private_ip_address_allocation = "Dynamic"
    }
  enable_accelerated_networking = "true"
}

resource "azurerm_windows_virtual_machine" "sapapp-vm" {
  name                = var.appvmname
  resource_group_name = azurerm_resource_group.sap-rg.name
  location            = var.location
  size                = var.appvmsize
  admin_username      = var.adminuser
  admin_password      = var.adminpassword
  network_interface_ids = [azurerm_network_interface.sapapp-nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "app-disks" {
  count  =  2
  name                 = join("-",[var.appvmname,"datadisk",count.index])
  location             =  var.location
  resource_group_name  =  azurerm_resource_group.sap-rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128

}

resource "azurerm_virtual_machine_data_disk_attachment" "app-disk-attach" {
  count = 2
  managed_disk_id    =  azurerm_managed_disk.app-disks[count.index].id
  virtual_machine_id =  azurerm_windows_virtual_machine.sapapp-vm.id
  lun                =  count.index
  caching            =  "ReadWrite"
  
}

resource "azurerm_public_ip" "bastion-pip" {
    name = "s4hanapoc-bastion-pip"
    location = var.location
    resource_group_name = azurerm_resource_group.sap-rg.name
    sku = "Standard"
    allocation_method = "Static"
}

resource "azurerm_bastion_host" "sap-bastion" {
    name = "S4HANA-POC-Bastion"
    location = var.location
    resource_group_name = azurerm_resource_group.sap-rg.name
    ip_configuration {
    name                 = "s4hanapoc-bastion-ipconfig01"
    subnet_id            = azurerm_subnet.bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
}