provider "azurerm" {
  features {}
}

provider "azuread" {

}

## hub resources
resource "azurerm_resource_group" "rg_hub" {
  name     = var.hub_rg
  location = var.location
}

resource "azurerm_virtual_network" "hub_vnet" {
  name                = "hubvnet"
  address_space       = [var.hub_vnet_address_space]
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name

}

resource "azurerm_subnet" "hub_subnet" {
  name                 = "hub_subnet"
  resource_group_name  = azurerm_resource_group.rg_hub.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = [var.hub_subnet_address_space]
}

resource "azurerm_subnet" "hub_bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg_hub.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = [var.hub_bastion_subnet_address_space]
}

# resource "azurerm_virtual_wan" "hub_wan" {
#   name                = "hub-vwan"
#   resource_group_name = azurerm_resource_group.rg_hub.name
#   location            = azurerm_resource_group.rg_hub.location
# }

# resource "azurerm_virtual_hub" "virtual_hub" {
#   name                = "virtual-hub"
#   resource_group_name = azurerm_resource_group.rg_hub.name
#   location            = azurerm_resource_group.rg_hub.location
#   virtual_wan_id      = azurerm_virtual_wan.hub_wan.id
#   address_prefix      = var.virtual_hub_address_space
# }

# resource "azurerm_vpn_gateway" "hub_vpn_gateway" {
#   name                = "hub-vpn-gw"
#   location            = azurerm_resource_group.rg_hub.location
#   resource_group_name = azurerm_resource_group.rg_hub.name
#   virtual_hub_id      = azurerm_virtual_hub.virtual_hub.id
# }

resource "azurerm_virtual_network_peering" "peer_hub_to_asc" {
  name                      = "hub2asc"
  resource_group_name       = azurerm_resource_group.rg_hub.name
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.asc_vnet.id
}

resource "azurerm_virtual_network_peering" "peer_asc_to_hub" {
  name                      = "asc2hub"
  resource_group_name       = azurerm_resource_group.rg_asc.name
  virtual_network_name      = azurerm_virtual_network.asc_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "bastion-ip"
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = "hubbastion"
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name
  ip_configuration {
    name                 = "bastion_ip_config"
    subnet_id            = azurerm_subnet.hub_bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "private.azuremicroservices.io"
  resource_group_name = azurerm_resource_group.rg_hub.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link_hub" {
  name                  = "hub-dns-link"
  resource_group_name   = azurerm_resource_group.rg_hub.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.hub_vnet.id
}

resource "azurerm_network_interface" "test_vm_nic" {
  name                = "test-vm-nic"
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "test-vm" {
  name                = "test-vm"
  resource_group_name = azurerm_resource_group.rg_hub.name
  location            = azurerm_resource_group.rg_hub.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.test_vm_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# # public access
# resource "azurerm_resource_group" "rg_public" {
#   name     = var.public_rg
#   location = var.location
# }
# resource "azurerm_virtual_network" "public_vnet" {
#   name                = "public-vnet"
#   resource_group_name = azurerm_resource_group.rg_public.name
#   location            = azurerm_resource_group.rg_public.location
#   address_space       = ["10.254.0.0/16"]
# }

# resource "azurerm_subnet" "frontend" {
#   name                 = "asc-frontend"
#   resource_group_name  = azurerm_resource_group.rg_public.name
#   virtual_network_name = azurerm_virtual_network.public_vnet.name
#   address_prefixes     = ["10.254.0.0/24"]
# }

# resource "azurerm_public_ip" "asc_public_ip" {
#   name                = "asc-petclinic-ip"
#   resource_group_name = azurerm_resource_group.rg_public.name
#   location            = azurerm_resource_group.rg_public.location
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# locals {
#   backend_address_pool_name      = "${azurerm_virtual_network.public_vnet.name}-beap"
#   frontend_port_name             = "${azurerm_virtual_network.public_vnet.name}-feport"
#   frontend_ip_configuration_name = "${azurerm_virtual_network.public_vnet.name}-feip"
#   http_setting_name              = "${azurerm_virtual_network.public_vnet.name}-be-htst"
#   listener_name                  = "${azurerm_virtual_network.public_vnet.name}-httplstn"
#   request_routing_rule_name      = "${azurerm_virtual_network.public_vnet.name}-rqrt"
#   redirect_configuration_name    = "${azurerm_virtual_network.public_vnet.name}-rdrcfg"
#   rewrite_routing_rule_name      = "${azurerm_virtual_network.public_vnet.name}-rwrtname"
#   rewrite_routing_rule_set_name  = "${azurerm_virtual_network.public_vnet.name}-rwrtsname"
#   backend_probe_name             = "${azurerm_virtual_network.public_vnet.name}-be-probe"
# }

# resource "azurerm_application_gateway" "app_gw" {
#   name                = "asc-appgateway"
#   resource_group_name = azurerm_resource_group.rg_public.name
#   location            = azurerm_resource_group.rg_public.location

#   sku {
#     name     = "Standard_v2"
#     tier     = "Standard_v2"
#     capacity = 2
#   }

#   gateway_ip_configuration {
#     name      = "asc-gateway-ip-configuration"
#     subnet_id = azurerm_subnet.frontend.id
#   }

#   frontend_port {
#     name = local.frontend_port_name
#     port = 80
#   }

#   frontend_ip_configuration {
#     name                 = local.frontend_ip_configuration_name
#     public_ip_address_id = azurerm_public_ip.asc_public_ip.id
#   }

#   backend_address_pool {
#     name  = local.backend_address_pool_name
#     fqdns = [azurerm_spring_cloud_app.api_gateway.fqdn]
#   }

#   backend_http_settings {
#     name                                = local.http_setting_name
#     cookie_based_affinity               = "Enabled"
#     path                                = "/"
#     port                                = 443
#     protocol                            = "Https"
#     request_timeout                     = 60
#     pick_host_name_from_backend_address = true
#     probe_name                          = local.backend_probe_name
#   }

#   probe {
#     name                                      = local.backend_probe_name
#     interval                                  = 30
#     unhealthy_threshold                       = 6
#     timeout                                   = 10
#     protocol                                  = "https"
#     pick_host_name_from_backend_http_settings = true
#     path                                      = "/"
#   }

#   http_listener {
#     name                           = local.listener_name
#     frontend_ip_configuration_name = local.frontend_ip_configuration_name
#     frontend_port_name             = local.frontend_port_name
#     protocol                       = "Http"
#   }

#   request_routing_rule {
#     name                       = local.request_routing_rule_name
#     rule_type                  = "Basic"
#     http_listener_name         = local.listener_name
#     backend_address_pool_name  = local.backend_address_pool_name
#     backend_http_settings_name = local.http_setting_name
#     # rewrite_rule_set_name      = local.rewrite_routing_rule_set_name
#   }

#   # rewrite_rule_set {
#   #   name = local.rewrite_routing_rule_set_name
#   #   rewrite_rule {
#   #     name          = local.rewrite_routing_rule_name
#   #     rule_sequence = 1
#   #     request_header_configuration {
#   #       header_name  = "X-Forwarded-Proto"
#   #       header_value = "https"
#   #     }
#   #   }
#   # }
# }


## Azure Spring Cloud resources (Spoke)

resource "azurerm_resource_group" "rg_asc" {
  name     = var.asc_rg
  location = var.location
}

locals {
  mysql_server_name  = "pcsms-db-${var.asc_rg}"
  app_insights_name  = "pcsms-appinsights-${var.asc_rg}"
  log_analytics_name = "pcsms-log-${var.asc_rg}"
}

resource "azurerm_virtual_network" "asc_vnet" {
  name                = var.asc_vnet
  address_space       = [var.asc_vnet_address_space]
  location            = azurerm_resource_group.rg_asc.location
  resource_group_name = azurerm_resource_group.rg_asc.name
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app_subnet"
  resource_group_name  = azurerm_resource_group.rg_asc.name
  virtual_network_name = azurerm_virtual_network.asc_vnet.name
  address_prefixes     = [var.asc_app_subnet_address_space]
}

resource "azurerm_subnet" "service_subnet" {
  name                 = "service_subnet"
  resource_group_name  = azurerm_resource_group.rg_asc.name
  virtual_network_name = azurerm_virtual_network.asc_vnet.name
  address_prefixes     = [var.asc_service_subnet_address_space]
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link_asc" {
  name                  = "asc-dns-link"
  resource_group_name   = azurerm_resource_group.rg_hub.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.asc_vnet.id
}



data "azuread_service_principal" "azure_spring_cloud_provisioner" {
  display_name = "Azure Spring Cloud Resource Provider"
}

# Make sure the SPID used to provision terraform has privilage to do role assignments. 
resource "azurerm_role_assignment" "ra" {
  scope                = azurerm_virtual_network.asc_vnet.id
  role_definition_name = "Owner"
  principal_id         = data.azuread_service_principal.azure_spring_cloud_provisioner.object_id
}

resource "azurerm_spring_cloud_service" "asc_service" {
  name                = var.asc_service_name
  resource_group_name = azurerm_resource_group.rg_asc.name
  location            = azurerm_resource_group.rg_asc.location

  # config_server_git_setting {
  #   uri          = var.config_repo_uri
  #   label        = "master"
  #   search_paths = ["."]
  #   http_basic_auth {
  #     username = var.config_repo_username
  #     password = var.config_repo_pat
  #   }
  # }

  trace {
    instrumentation_key = azurerm_application_insights.appinsights.instrumentation_key
  }

  network {
    app_subnet_id             = azurerm_subnet.app_subnet.id
    service_runtime_subnet_id = azurerm_subnet.service_subnet.id
    cidr_ranges               = ["10.4.0.0/16", "10.5.0.0/16", "10.3.0.1/16"]
  }


  depends_on = [
    azurerm_role_assignment.ra
  ]
}

data "azurerm_lb" "asc_internal_lb" {
  resource_group_name = "ap-svc-rt_${azurerm_spring_cloud_service.asc_service.name}_${azurerm_spring_cloud_service.asc_service.location}"
  name                = "kubernetes-internal"
  depends_on = [
    azurerm_spring_cloud_service.asc_service
  ]
}

resource "azurerm_private_dns_a_record" "internal_lb_record" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = azurerm_resource_group.rg_hub.name
  ttl                 = 300
  records             = [data.azurerm_lb.asc_internal_lb.private_ip_address]
}



resource "azurerm_spring_cloud_app" "api_gateway" {
  name                = var.api_gateway
  resource_group_name = azurerm_resource_group.rg_asc.name
  service_name        = azurerm_spring_cloud_service.asc_service.name
  is_public           = true
}

resource "azurerm_spring_cloud_java_deployment" "api_gateway_deployment" {
  # name                = "${var.api_gateway}-deployment"
  name                = "default"
  spring_cloud_app_id = azurerm_spring_cloud_app.api_gateway.id
  cpu                 = 1
  instance_count      = 1
  memory_in_gb        = 2
  jvm_options         = "-Xms2048m -Xmx2048m"
  runtime_version     = "Java_8"
}

resource "azurerm_spring_cloud_active_deployment" "api_gateway_deployment" {
  spring_cloud_app_id = azurerm_spring_cloud_app.api_gateway.id
  deployment_name     = azurerm_spring_cloud_java_deployment.api_gateway_deployment.name
}


resource "azurerm_spring_cloud_app" "admin_server" {
  name                = var.admin_server
  resource_group_name = azurerm_resource_group.rg_asc.name
  service_name        = azurerm_spring_cloud_service.asc_service.name
}

resource "azurerm_spring_cloud_java_deployment" "admin_server_deployment" {
  # name                = "${var.admin_server}-deployment"
  name                = "default"
  spring_cloud_app_id = azurerm_spring_cloud_app.admin_server.id
  cpu                 = 1
  instance_count      = 1
  memory_in_gb        = 2
  jvm_options         = "-Xms2048m -Xmx2048m"
  runtime_version     = "Java_8"
  environment_variables = {
    "Env" : "staging"
  }
}

resource "azurerm_spring_cloud_active_deployment" "admin_server_deployment" {
  spring_cloud_app_id = azurerm_spring_cloud_app.admin_server.id
  deployment_name     = azurerm_spring_cloud_java_deployment.admin_server_deployment.name
}



resource "azurerm_spring_cloud_app" "customers_service" {
  name                = var.customers_service
  resource_group_name = azurerm_resource_group.rg_asc.name
  service_name        = azurerm_spring_cloud_service.asc_service.name
}

resource "azurerm_spring_cloud_java_deployment" "customers_service_deployment" {
  # name                = "${var.customers_service}-deployment"
  name                = "default"
  spring_cloud_app_id = azurerm_spring_cloud_app.customers_service.id
  cpu                 = 1
  instance_count      = 1
  memory_in_gb        = 2
  jvm_options         = "-Xms2048m -Xmx2048m"
  runtime_version     = "Java_8"
  environment_variables = {
    "Env" : "staging"
  }
}

resource "azurerm_spring_cloud_active_deployment" "customers_service_deployment" {
  spring_cloud_app_id = azurerm_spring_cloud_app.customers_service.id
  deployment_name     = azurerm_spring_cloud_java_deployment.customers_service_deployment.name
}

resource "azurerm_spring_cloud_app_mysql_association" "customers_mysql_bind" {
  name                = "customers-mysql-bind"
  spring_cloud_app_id = azurerm_spring_cloud_app.customers_service.id
  mysql_server_id     = azurerm_mysql_server.asc_mysql_server.id
  database_name       = azurerm_mysql_database.asc_petclinic_db.name
  username            = azurerm_mysql_server.asc_mysql_server.administrator_login
  password            = azurerm_mysql_server.asc_mysql_server.administrator_login_password
}


resource "azurerm_spring_cloud_app" "vets_service" {
  name                = var.vets_service
  resource_group_name = azurerm_resource_group.rg_asc.name
  service_name        = azurerm_spring_cloud_service.asc_service.name
}

resource "azurerm_spring_cloud_java_deployment" "vets_service_deployment" {
  # name                = "${var.vets_service}-deployment"
  name                = "default"
  spring_cloud_app_id = azurerm_spring_cloud_app.vets_service.id
  cpu                 = 1
  instance_count      = 1
  memory_in_gb        = 2
  jvm_options         = "-Xms2048m -Xmx2048m"
  runtime_version     = "Java_8"
  environment_variables = {
    "Env" : "staging"
  }
}
resource "azurerm_spring_cloud_active_deployment" "vets_service_deployment" {
  spring_cloud_app_id = azurerm_spring_cloud_app.vets_service.id
  deployment_name     = azurerm_spring_cloud_java_deployment.vets_service_deployment.name
}

resource "azurerm_spring_cloud_app_mysql_association" "vets_mysql_bind" {
  name                = "vets-mysql-bind"
  spring_cloud_app_id = azurerm_spring_cloud_app.vets_service.id
  mysql_server_id     = azurerm_mysql_server.asc_mysql_server.id
  database_name       = azurerm_mysql_database.asc_petclinic_db.name
  username            = azurerm_mysql_server.asc_mysql_server.administrator_login
  password            = azurerm_mysql_server.asc_mysql_server.administrator_login_password
}


resource "azurerm_spring_cloud_app" "visits_service" {
  name                = var.visits_service
  resource_group_name = azurerm_resource_group.rg_asc.name
  service_name        = azurerm_spring_cloud_service.asc_service.name
}

resource "azurerm_spring_cloud_java_deployment" "visits_service_deployment" {
  # name                = "${var.visits_service}-deployment"
  name                = "default"
  spring_cloud_app_id = azurerm_spring_cloud_app.visits_service.id
  cpu                 = 1
  instance_count      = 1
  memory_in_gb        = 2
  jvm_options         = "-Xms2048m -Xmx2048m"
  runtime_version     = "Java_8"
  environment_variables = {
    "Env" : "staging"
  }
}

resource "azurerm_spring_cloud_active_deployment" "visits_service_deployment" {
  spring_cloud_app_id = azurerm_spring_cloud_app.visits_service.id
  deployment_name     = azurerm_spring_cloud_java_deployment.visits_service_deployment.name
}

resource "azurerm_spring_cloud_app_mysql_association" "visits_mysql_bind" {
  name                = "visits-mysql-bind"
  spring_cloud_app_id = azurerm_spring_cloud_app.visits_service.id
  mysql_server_id     = azurerm_mysql_server.asc_mysql_server.id
  database_name       = azurerm_mysql_database.asc_petclinic_db.name
  username            = azurerm_mysql_server.asc_mysql_server.administrator_login
  password            = azurerm_mysql_server.asc_mysql_server.administrator_login_password
}

resource "random_password" "mysql_pwd" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_mysql_server" "asc_mysql_server" {
  name                = local.mysql_server_name
  location            = azurerm_resource_group.rg_asc.location
  resource_group_name = azurerm_resource_group.rg_asc.name

  sku_name = "GP_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = true

  administrator_login          = var.mysql_server_admin_name
  administrator_login_password = random_password.mysql_pwd.result
  version                      = "5.7"
  ssl_enforcement_enabled      = true
}

resource "azurerm_mysql_database" "asc_petclinic_db" {
  name                = var.mysql_database_name
  resource_group_name = azurerm_resource_group.rg_asc.name
  server_name         = azurerm_mysql_server.asc_mysql_server.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_firewall_rule" "allazureips" {
  name                = "allAzureIPs"
  resource_group_name = azurerm_resource_group.rg_asc.name
  server_name         = azurerm_mysql_server.asc_mysql_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_mysql_configuration" "mysql_timeout" {
  name                = "interactive_timeout"
  resource_group_name = azurerm_resource_group.rg_asc.name
  server_name         = azurerm_mysql_server.asc_mysql_server.name
  value               = "2147483"
}

resource "azurerm_mysql_configuration" "mysql_time_zone" {
  name                = "time_zone"
  resource_group_name = azurerm_resource_group.rg_asc.name
  server_name         = azurerm_mysql_server.asc_mysql_server.name
  value               = "+2:00" // Add appropriate offset based on your region.
}

# resource "azurerm_log_analytics_workspace" "loganalytics" {
#   name                = local.log_analytics_name
#   location            = azurerm_resource_group.rg_asc.location
#   resource_group_name = azurerm_resource_group.rg_asc.name
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
# }

resource "azurerm_application_insights" "appinsights" {
  name                = local.app_insights_name
  location            = azurerm_resource_group.rg_asc.location
  resource_group_name = azurerm_resource_group.rg_asc.name

  application_type = "java"
}
