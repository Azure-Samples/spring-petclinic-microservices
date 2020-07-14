# Introduction

This repository hosts instructional and sample content for using Azure Spring Cloud with Azure Pipelines.

# Contents

[settings-example.xml](settings-example.xml) - An illustration of the `settings.xml` file enabling the Maven build to use Azure Artifacts.

[main.tf](main.tf) - Terraform script with all the necessary resources to deploy Petclinic app along with Azure spring cloud service instance. The script also provions a VNET and two subnets and adds a CIDR block to Azure spring cloud instance. 

[provision-resources-vnet-terraform.yml](provision-resources.yml) - An Azure pipeline to provision (via Terraform scirpt  above) and configure all required resources for the application. The pipeline builds a private copy of Terraform from the following [repository](https://github.com/njuCZ/terraform-provider-azurerm/tree/spring_cloud_service_vnet_integration). It initialized remote backend to the variables provided for the terraform task and then applies the script. At the successful conclusion of this pipeline, the application is ready to build and deploy.

[stage-deploy-asc-app-terraform.yml](stage-deploy-asc-app-terraform.yml) - An Azure pipeline to deploy applications on to the provisioned Azure spring cloud instance above. This pipeline is kicked off by running the [build pipeline](..\azure-pipelines\azure-pipelines-build.yml) 