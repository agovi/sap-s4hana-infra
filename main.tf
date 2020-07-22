provider "azurerm" {
  version = "=2.10.0"
  features {}
}

locals {
  generaltags = {
    asset-insight-id = var.asset-insight-id
    create-date      = formatdate("DD-MMM-YYYY", timestamp())
    creator-email    = var.creator-email
    creator-id       = var.creator-id
  }
}

resource "azurerm_resource_group" "sap-rg" {
  name     = var.rgname
  location = var.location
  tags     = local.generaltags
}

resource "azurerm_virtual_network" "sap-vnet" {
  name                = "s4hana-poc-vnet"
  resource_group_name = azurerm_resource_group.sap-rg.name
  location            = var.location
  address_space       = [for num in var.vnetprefix : num]
  tags                = local.generaltags
}

resource "azurerm_subnet" "sap-app-subnet" {
  name                 = "sap-app-subnet"
  resource_group_name  = azurerm_resource_group.sap-rg.name
  virtual_network_name = azurerm_virtual_network.sap-vnet.name
  address_prefixes     = [var.sapappsubnet]

}

resource "azurerm_subnet" "sap-db-subnet" {
  name                 = "sap-db-subnet"
  resource_group_name  = azurerm_resource_group.sap-rg.name
  virtual_network_name = azurerm_virtual_network.sap-vnet.name
  address_prefixes     = [var.sapdbsubnet]

}

resource "azurerm_subnet" "sap-hub-subnet" {
  name                 = "sap-hub-subnet"
  resource_group_name  = azurerm_resource_group.sap-rg.name
  virtual_network_name = azurerm_virtual_network.sap-vnet.name
  address_prefixes     = [var.hubsubnet]
}

resource "azurerm_subnet" "bastion-subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.sap-rg.name
  virtual_network_name = azurerm_virtual_network.sap-vnet.name
  address_prefixes     = [var.bastionsubnet]
}

resource "azurerm_network_security_group" "sap-db-nsg" {
  name                = "SAPDatabaseNsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name

  security_rule {
    name                       = "HANAPortsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["30015", "30013", "50013"]
    source_address_prefix      = var.sapappsubnet
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
    source_address_prefix      = var.bastionsubnet
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "InboundDeny"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = local.generaltags
}


resource "azurerm_network_security_group" "sap-app-nsg" {
  name                = "SAPApplicationNsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name

  security_rule {
    name                       = "SAPApplicationPortsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["3200", "3300", "3600", "3900", "8000", "8001"]
    source_address_prefix      = var.hubsubnet
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
    source_address_prefix      = var.bastionsubnet
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSHfromHub"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.hubsubnet
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "InboundDeny"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = local.generaltags

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
    name                       = "BastionInboundDeny"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
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
  tags = local.generaltags
}


resource "azurerm_network_security_group" "hub-nsg" {
  name                = "HubNsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name

  security_rule {
    name                       = "AllowSAPSupportInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3299"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RDPfromBastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.bastionsubnet
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "BastionInboundDeny"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = local.generaltags
}

resource "azurerm_subnet_network_security_group_association" "sap-app-nsg-assc" {
  subnet_id                 = azurerm_subnet.sap-app-subnet.id
  network_security_group_id = azurerm_network_security_group.sap-app-nsg.id
}


resource "azurerm_subnet_network_security_group_association" "sap-db-nsg-assc" {
  subnet_id                 = azurerm_subnet.sap-db-subnet.id
  network_security_group_id = azurerm_network_security_group.sap-db-nsg.id
}

resource "azurerm_subnet_network_security_group_association" "hub-nsg-assc" {
  subnet_id                 = azurerm_subnet.sap-hub-subnet.id
  network_security_group_id = azurerm_network_security_group.hub-nsg.id
}

resource "azurerm_subnet_network_security_group_association" "bastion-nsg-assc" {
  subnet_id                 = azurerm_subnet.bastion-subnet.id
  network_security_group_id = azurerm_network_security_group.bastion-nsg.id
}

resource "azurerm_proximity_placement_group" "sap-ppg" {
  name                = "S4HANA-PPG"
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name
  tags                = local.generaltags
}


resource "azurerm_network_interface" "sapdb-nic" {
  depends_on          = [azurerm_subnet_network_security_group_association.sap-db-nsg-assc]
  name                = join("-", [var.dbvmname, "nic"])
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name
  ip_configuration {
    name                          = join("-", [var.dbvmname, "ipconfig01"])
    subnet_id                     = azurerm_subnet.sap-db-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  enable_accelerated_networking = "true"
  tags                          = local.generaltags
}

resource "azurerm_linux_virtual_machine" "sapdb-vm" {
  name                            = var.dbvmname
  location                        = var.location
  resource_group_name             = azurerm_resource_group.sap-rg.name
  size                            = var.dbvmsize
  admin_username                  = "azureuser"
  network_interface_ids           = [azurerm_network_interface.sapdb-nic.id]
  admin_password                  = var.adminpassword
  proximity_placement_group_id    = azurerm_proximity_placement_group.sap-ppg.id
  disable_password_authentication = "false"

  os_disk {
    name                 = join("-", [var.dbvmname, "osdisk"])
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "SUSE"
    offer     = "SLES-SAP"
    sku       = "12-SP4"
    version   = "latest"
  }
  tags = local.generaltags

}

resource "azurerm_managed_disk" "db-disks" {
  count                = length(var.dbdiskluns)
  name                 = join("-", [var.dbvmname, "datadisk", count.index])
  location             = var.location
  resource_group_name  = azurerm_resource_group.sap-rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.dbdisksizes[count.index]
  tags                 = local.generaltags
}

resource "azurerm_virtual_machine_data_disk_attachment" "db-disk-attach" {
  count                     = length(var.dbdiskluns)
  managed_disk_id           = azurerm_managed_disk.db-disks[count.index].id
  virtual_machine_id        = azurerm_linux_virtual_machine.sapdb-vm.id
  lun                       = var.dbdiskluns[count.index]
  caching                   = var.dbdiskcache[count.index]
  write_accelerator_enabled = var.dbdiskwaflag[count.index]
}

resource "azurerm_virtual_machine_extension" "db-fscreate" {
  depends_on           = [azurerm_virtual_machine_data_disk_attachment.db-disk-attach]
  name                 = var.dbvmname
  virtual_machine_id   = azurerm_linux_virtual_machine.sapdb-vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  protected_settings   = <<SETTINGS
    {
      "script" : "${base64encode(file("fscreate.sh"))}"
    }
  SETTINGS
}

resource "azurerm_public_ip" "sap-router-pip" {
  name                = "SAP-Router-PublicIP"
  resource_group_name = azurerm_resource_group.sap-rg.name
  location            = var.location
  allocation_method   = "Dynamic"
  tags                = local.generaltags
}


resource "azurerm_network_interface" "sapapp-nic" {
  depends_on          = [azurerm_subnet_network_security_group_association.sap-app-nsg-assc]
  name                = join("-", [var.appvmname, "nic"])
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name

  ip_configuration {
    name                          = join("-", [var.appvmname, "ipconfig01"])
    subnet_id                     = azurerm_subnet.sap-app-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  enable_accelerated_networking = "true"
  tags                          = local.generaltags
}

resource "azurerm_linux_virtual_machine" "sapapp-vm" {
  ## Use DB VM as anchor for the PPG
  depends_on                      = [azurerm_linux_virtual_machine.sapdb-vm]
  name                            = var.appvmname
  location                        = var.location
  resource_group_name             = azurerm_resource_group.sap-rg.name
  size                            = var.appvmsize
  admin_username                  = "azureuser"
  network_interface_ids           = [azurerm_network_interface.sapapp-nic.id]
  admin_password                  = var.adminpassword
  proximity_placement_group_id    = azurerm_proximity_placement_group.sap-ppg.id
  disable_password_authentication = "false"

  os_disk {
    name                 = join("-", [var.appvmname, "osdisk"])
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "SUSE"
    offer     = "SLES-SAP"
    sku       = "12-SP4"
    version   = "latest"
  }
  tags = local.generaltags
}

resource "azurerm_managed_disk" "app-disks" {
  name                 = join("-", [var.appvmname, "datadisk", "0"])
  location             = var.location
  resource_group_name  = azurerm_resource_group.sap-rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
  tags                 = local.generaltags
}

resource "azurerm_virtual_machine_data_disk_attachment" "app-disk-attach" {
  managed_disk_id    = azurerm_managed_disk.app-disks.id
  virtual_machine_id = azurerm_linux_virtual_machine.sapapp-vm.id
  lun                = "0"
  caching            = "ReadWrite"
}

resource "azurerm_network_interface" "saprouter-nic" {
  depends_on          = [azurerm_subnet_network_security_group_association.hub-nsg-assc]
  name                = join("-", [var.routervmname, "nic"])
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name

  ip_configuration {
    name                          = join("-", [var.routervmname, "ipconfig01"])
    subnet_id                     = azurerm_subnet.sap-hub-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.sap-router-pip.id
  }
  enable_accelerated_networking = "false"
  tags                          = local.generaltags
}



resource "azurerm_windows_virtual_machine" "saprouter-vm" {
  name                  = var.routervmname
  resource_group_name   = azurerm_resource_group.sap-rg.name
  location              = var.location
  size                  = var.routervmsize
  admin_username        = var.adminuser
  admin_password        = var.adminpassword
  network_interface_ids = [azurerm_network_interface.saprouter-nic.id]

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
  tags = local.generaltags
}

resource "azurerm_managed_disk" "router-disks" {
  name                 = join("-", [var.routervmname, "datadisk", "0"])
  location             = var.location
  resource_group_name  = azurerm_resource_group.sap-rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 64
  tags                 = local.generaltags
}

resource "azurerm_virtual_machine_data_disk_attachment" "router-disk-attach" {
  managed_disk_id    = azurerm_managed_disk.router-disks.id
  virtual_machine_id = azurerm_windows_virtual_machine.saprouter-vm.id
  lun                = "0"
  caching            = "ReadWrite"

}

resource "azurerm_public_ip" "bastion-pip" {
  name                = "s4hanapoc-bastion-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = local.generaltags
}

resource "azurerm_bastion_host" "sap-bastion" {
  depends_on          = [azurerm_subnet_network_security_group_association.bastion-nsg-assc]
  name                = "SAP-POC-Bastion"
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name
  ip_configuration {
    name                 = "s4hanapoc-bastion-ipconfig01"
    subnet_id            = azurerm_subnet.bastion-subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
  tags = local.generaltags
}

resource "azurerm_public_ip" "sap-loadbalancer-pip" {
  name                = "SAP-Loadbalancer-PublicIP"
  resource_group_name = azurerm_resource_group.sap-rg.name
  location            = var.location
  allocation_method   = "Dynamic"
  tags                = local.generaltags
}


resource "azurerm_lb" "sap-access-lb" {
  name                = "SAPAccessLoadBalancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.sap-rg.name
  frontend_ip_configuration {
    name                 = "SAPAccessPublicIP"
    public_ip_address_id = azurerm_public_ip.sap-loadbalancer-pip.id
  }
  tags = local.generaltags
}

resource "azurerm_lb_nat_rule" "sap-access-nat" {
  count                          = length(var.natports)
  resource_group_name            = azurerm_resource_group.sap-rg.name
  loadbalancer_id                = azurerm_lb.sap-access-lb.id
  name                           = join("-", ["Natrule-", var.natports[count.index]])
  protocol                       = "Tcp"
  frontend_port                  = var.natports[count.index]
  backend_port                   = var.natports[count.index]
  frontend_ip_configuration_name = "SAPAccessPublicIP"
  idle_timeout_in_minutes        = 30
}

resource "azurerm_network_interface_nat_rule_association" "sap-backend-pool" {
  count                 = length(var.natports)
  network_interface_id  = azurerm_network_interface.sapapp-nic.id
  ip_configuration_name = join("-", [var.appvmname, "ipconfig01"])
  nat_rule_id           = azurerm_lb_nat_rule.sap-access-nat[count.index].id
}

