variable "location" {
  type        = string
  description = "Azure region to host all services"
  default     = "westeurope"
}

variable "public_rg" {
  type        = string
  description = "resource group for all publicly exposed resources"
}

variable "hub_rg" {
  type        = string
  description = "resource group for hub components"
}
variable "hub_vnet_address_space" {
  type        = string
  description = "Hub vnet address space"
  default     = "10.12.0.0/16"
}

variable "hub_subnet_address_space" {
  type        = string
  description = "Hub subnet address space"
  default     = "10.12.0.0/24"
}

variable "virtual_hub_address_space" {
  type        = string
  description = "Virtual hub address space"
  default     = "10.12.1.0/24"
}
variable "hub_bastion_subnet_address_space" {
  type        = string
  description = "Bastion subnet address space"
  default     = "10.12.2.0/27"
}


variable "asc_rg" {
  type        = string
  description = "resource group that contains Azure Spring Cloud deployment"
}

variable "asc_service_name" {
  type        = string
  description = "Azure Spring Cloud service name. It should be unique in the world, so it is a good idea to add your alias in the name"
}

variable "asc_vnet" {
  type        = string
  description = "Name of the vnet to deploy Azure Spring Cloud service"
}

variable "asc_vnet_address_space" {
  type        = string
  description = "VNet address space"
  default     = "10.11.0.0/16"
}

variable "asc_app_subnet_address_space" {
  type        = string
  description = "Application subnet address space"
  default     = "10.11.1.0/24"
}
variable "asc_service_subnet_address_space" {
  type        = string
  description = "Service subnet address space"
  default     = "10.11.2.0/24"
}

variable "config_repo_uri" {
  type        = string
  description = "repository that hosts the configuration"

}

variable "config_repo_username" {
  type        = string
  description = "username of githu configuration repository"
}

variable "config_repo_pat" {
  type        = string
  description = "personal access token for github configuration repository"
}




##

variable "api_gateway" {
  type    = string
  default = "api-gateway"
}
variable "admin_server" {
  type    = string
  default = "admin-server"
}
variable "customers_service" {
  type    = string
  default = "customers-service"
}
variable "visits_service" {
  type    = string
  default = "visits-service"
}

variable "vets_service" {
  type    = string
  default = "vets-service"
}

variable "mysql_server_admin_name" {
  type    = string
  default = "sqlAdmin"
}

# variable "mysql_server_admin_password" {
#   type = string
# }

variable "mysql_database_name" {
  type    = string
  default = "petclinic"
}
