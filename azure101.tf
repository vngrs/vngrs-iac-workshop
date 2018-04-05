variable "azure_region" {
  type = "string"
  description = "Azure Region name"
  default = "West Europe"
}

variable "resource_group_name" {
  type = "string"
  description = "Resource Group name"
}

variable "mysql_server_name" {
  type = "string"
  description = "Name of your mysql server name"
}

provider "azurerm" {
}

resource "azurerm_resource_group" "iac_ws_tf_rg" {
  name = "${var.resource_group_name}"
  location = "${var.azure_region}"
}

resource "azurerm_virtual_network" "iac_ws_tf_vn" {
  name = "iac_ws_tf_vn"
  address_space = ["10.99.0.0/16"]
  location = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.iac_ws_tf_rg.name}"
}

resource "azurerm_subnet" "iac_ws_tf_public_sn" {
  name = "iac_ws_tf_public_sn"
  address_prefix = "10.99.0.0/24"
  resource_group_name = "${azurerm_resource_group.iac_ws_tf_rg.name}"
  virtual_network_name = "${azurerm_virtual_network.iac_ws_tf_vn.name}"
}

resource "azurerm_subnet" "iac_ws_tf_private_sn" {
  name = "iac_ws_tf_private_sn" 
  address_prefix = "10.99.100.0/24"
  resource_group_name = "${azurerm_resource_group.iac_ws_tf_rg.name}"
  virtual_network_name = "${azurerm_virtual_network.iac_ws_tf_vn.name}" 
}

resource "azurerm_network_security_group" "iac_ws_tf_sample_app_vm_nsg" {
    name                = "iac_ws_tf_sample_app_vm_nsg"
    location            = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.iac_ws_tf_rg.name}"
    security_rule {
        name                       = "HTTP"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_public_ip" "iac_ws_tf_ip_for_lb" {
  name                         = "iac_ws_tf_ip_for_lb"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.iac_ws_tf_rg.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_lb" "iac_ws_tf_lb" {
  name                = "iac_ws_tf_lb"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.iac_ws_tf_rg.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.iac_ws_tf_ip_for_lb.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "iac_ws_tf_be_addr_pool" {
  resource_group_name = "${azurerm_resource_group.iac_ws_tf_rg.name}"
  loadbalancer_id     = "${azurerm_lb.iac_ws_tf_lb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_rule" "iac_ws_tf_lb_rule" {
  resource_group_name            = "${azurerm_resource_group.iac_ws_tf_rg.name}"
  loadbalancer_id                = "${azurerm_lb.iac_ws_tf_lb.id}"
  name                           = "iac_ws_tf_lb_rule"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.iac_ws_tf_be_addr_pool.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.iac_ws_tf_lb_probe.id}"
  depends_on                     = ["azurerm_lb_probe.iac_ws_tf_lb_probe"]
}

resource "azurerm_lb_probe" "iac_ws_tf_lb_probe" {
  resource_group_name = "${azurerm_resource_group.iac_ws_tf_rg.name}"
  loadbalancer_id     = "${azurerm_lb.iac_ws_tf_lb.id}"
  name                = "tcpProbe"
  protocol            = "tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_network_interface" "iac_ws_tf_sample_app_vm_nic" {
    name                = "iac_ws_tf_sample_app_vm_nic"
    location            = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.iac_ws_tf_rg.name}"

    ip_configuration {
        name                          = "iac_ws_tf_sample_app_vm_nic"
        subnet_id                     = "${azurerm_subnet.iac_ws_tf_private_sn.id}"
        private_ip_address_allocation = "dynamic"
        load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.iac_ws_tf_be_addr_pool.id}"]

    }

    tags {
        environment = "Terraform Demo"
    }
}

resource "azurerm_mysql_server" "iac_ws_tf_sample_db" {
  name                = "${var.mysql_server_name}"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.iac_ws_tf_rg.name}"

  sku {
    name = "MYSQLB50"
    capacity = 50
    tier = "Basic"
  }

  administrator_login = "db_admin"
  administrator_login_password = "Password!123"
  version = "5.7"
  storage_mb = "51200"
  ssl_enforcement = "Enabled"
}

resource "azurerm_mysql_database" "sampledb" {
  name                = "sampledb"
  resource_group_name = "${azurerm_resource_group.iac_ws_tf_rg.name}"
  server_name         = "${azurerm_mysql_server.iac_ws_tf_sample_db.name}"
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_firewall_rule" "test" {
  name                = "all"
  resource_group_name = "${azurerm_resource_group.iac_ws_tf_rg.name}"
  server_name         = "${azurerm_mysql_server.iac_ws_tf_sample_db.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}


# VM Starts here
data "template_file" "cloud_init_file" {
  template = "${file("cloud-init.conf.tpl")}"

  vars {
    mysql_host = "${azurerm_mysql_server.iac_ws_tf_sample_db.fqdn}"
    mysql_user = "${azurerm_mysql_server.iac_ws_tf_sample_db.administrator_login}"
    mysql_passwd = "${azurerm_mysql_server.iac_ws_tf_sample_db.administrator_login_password}"
    mysql_db = "${azurerm_mysql_database.sampledb.name}"
    mysql_server_name = "${azurerm_mysql_server.iac_ws_tf_sample_db.name}"
  }
}

resource "azurerm_virtual_machine" "iac_ws_tf_sample_app_vm" {
  name                  = "iac_ws_tf_sample_app_vm"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.iac_ws_tf_rg.name}"
  network_interface_ids = ["${azurerm_network_interface.iac_ws_tf_sample_app_vm_nic.id}"]
  vm_size               = "Standard_A0"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "iac_ws_tf_sample_app_disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "sampleappvm"
    admin_username = "testadmin"
    admin_password = "Password1234!"
    custom_data = "${data.template_file.cloud_init_file.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

