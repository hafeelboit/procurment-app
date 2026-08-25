# ============================================================
# RESOURCE GROUP
# ============================================================

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ============================================================
# VIRTUAL NETWORK
# ============================================================

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ansible-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  address_space = ["10.10.0.0/16"]
}

# ============================================================
# SUBNET
# ============================================================

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-ansible"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = ["10.10.1.0/24"]
}

# ============================================================
# PUBLIC IP
# ONLY FOR ANSIBLE CONTROL SERVER
# ============================================================

resource "azurerm_public_ip" "ansible_control" {
  name                = "pip-ansible-control"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"
}

# ============================================================
# NSG FOR ANSIBLE CONTROL SERVER
# ============================================================

resource "azurerm_network_security_group" "control_nsg" {
  name                = "nsg-ansible-control"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name      = "Allow-SSH"
    priority  = 100
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range      = "*"
    destination_port_range = "22"

    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ============================================================
# NSG FOR 5 UBUNTU TARGET SERVERS
# SSH ALLOWED ONLY FROM VNET
# ============================================================

resource "azurerm_network_security_group" "target_nsg" {
  name                = "nsg-ubuntu-targets"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name      = "Allow-SSH-From-VNet"
    priority  = 100
    direction = "Inbound"
    access    = "Allow"
    protocol  = "Tcp"

    source_port_range      = "*"
    destination_port_range = "22"

    source_address_prefix      = "10.10.0.0/16"
    destination_address_prefix = "*"
  }
}

# ============================================================
# ANSIBLE CONTROL SERVER NIC
# ============================================================

resource "azurerm_network_interface" "ansible_control" {
  name                = "nic-ansible-control"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "internal"

    subnet_id = azurerm_subnet.subnet.id

    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.ansible_control.id
  }
}

# ============================================================
# ATTACH CONTROL NSG TO CONTROL NIC
# ============================================================

resource "azurerm_network_interface_security_group_association" "control_nsg_association" {
  network_interface_id      = azurerm_network_interface.ansible_control.id
  network_security_group_id = azurerm_network_security_group.control_nsg.id
}

# ============================================================
# ANSIBLE CONTROL SERVER
# ============================================================

resource "azurerm_linux_virtual_machine" "ansible_control" {
  name = "ansible-control"

  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  size = var.vm_size

  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.ansible_control.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Install Ansible automatically
  custom_data = base64encode(<<-EOF
    #!/bin/bash

    apt-get update -y

    apt-get install -y \
      ansible \
      git \
      curl \
      unzip

    mkdir -p /home/${var.admin_username}/ansible

    chown -R ${var.admin_username}:${var.admin_username} \
      /home/${var.admin_username}/ansible

  EOF
  )
}

# ============================================================
# 5 UBUNTU TARGET SERVER NICs
# ============================================================

resource "azurerm_network_interface" "target" {
  count = 2

  name                = "nic-ubuntu-${format("%02d", count.index + 1)}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "internal"

    subnet_id = azurerm_subnet.subnet.id

    private_ip_address_allocation = "Dynamic"
  }
}

# ============================================================
# ATTACH TARGET NSG TO 5 TARGET NICs
# ============================================================

resource "azurerm_network_interface_security_group_association" "target_nsg_association" {
  count = 2

  network_interface_id      = azurerm_network_interface.target[count.index].id
  network_security_group_id = azurerm_network_security_group.target_nsg.id
}

# ============================================================
# 5 UBUNTU TARGET SERVERS
# ============================================================

resource "azurerm_linux_virtual_machine" "ubuntu" {
  count = 2

  name = "ubuntu-vm-${format("%02d", count.index + 1)}"

  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  size = var.vm_size

  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.target[count.index].id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}