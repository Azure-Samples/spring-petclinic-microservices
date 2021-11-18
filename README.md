---
page_type: sample
languages:
- java
products:
- Azure Spring Cloud
description: "Deploy Spring Boot apps using Azure Spring Cloud and MySQL"
urlFragment: "spring-petclinic-microservices"
---

# Deploy Spring Boot apps using Azure Spring Cloud and MySQL 

Azure Spring Cloud enables you to easily run a Spring Boot applications on Azure.

This quickstart shows you how to deploy an existing Java Spring Cloud application to Azure. When 
you're finished, you can continue to manage the application via the Azure CLI or switch to using the 
Azure Portal.

* [Deploy Spring Boot apps using Azure Spring Cloud and MySQL](#deploy-spring-boot-apps-using-azure-spring-cloud-and-mysql)
  * [What will you experience](#what-will-you-experience)
  * [What you will need](#what-you-will-need)
  * [Install the Azure CLI extension](#install-the-azure-cli-extension)
  * [Clone and build the repo](#clone-and-build-the-repo)
  * [Unit 1 - Deploy and monitor Spring Boot apps](#unit-1---deploy-and-monitor-spring-boot-apps)
  * [Unit 2 - AUTOMATE deployments using GitHub Actions](#unit-2---automate-deployments-using-github-actions)
  * [Unit 3 - Manage application secrets using Azure KeyVault](#unit-3---manage-application-secrets-using-azure-keyvault)
  * [Next Steps](#next-steps)

## What will you experience
You will:
- Build existing Spring Boot applications
- Provision an Azure Spring Cloud service instance. If you prefer Terraform, you may also provision using Terraform, see [`README-terraform`](./terraform/README-terraform.md)
- Deploy applications to Azure
- Bind applications to Azure Database for MySQL
- Open the application
- Monitor applications
- Automate deployments using GitHub Actions
- Manage application secrets using Azure KeyVault

## What you will need

In order to deploy a Java app to cloud, you need 
an Azure subscription. If you do not already have an Azure 
subscription, you can activate your 
[MSDN subscriber benefits](https://azure.microsoft.com/pricing/member-offers/msdn-benefits-details/) 
or sign up for a 
[free Azure account]((https://azure.microsoft.com/free/)).

In addition, you will need the following:

| [Azure CLI version 2.17.1 or higher](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) 
| [Java 8](https://www.azul.com/downloads/azure-only/zulu/?version=java-8-lts&architecture=x86-64-bit&package=jdk) 
| [Maven](https://maven.apache.org/download.cgi) 
| [MySQL CLI](https://dev.mysql.com/downloads/shell/)
| [Git](https://git-scm.com/)
| [`jq` utility](https://stedolan.github.io/jq/download/)
|

Note -  The [`jq` utility](https://stedolan.github.io/jq/download/). On Windows, download [this Windows port of JQ](https://github.com/stedolan/jq/releases) and add the following to the `~/.bashrc` file: 
           ```bash
           alias jq=<JQ Download location>/jq-win64.exe
           ```

Note - The Bash shell. While Azure CLI should behave identically on all environments, shell 
semantics vary. Therefore, only bash can be used with the commands in this repo. 
To complete these repo steps on Windows, use Git Bash that accompanies the Windows distribution of 
Git. Use only Git Bash to complete this training on Windows. Do not use WSL.

### OR Use Azure Cloud Shell

Or, you can use the Azure Cloud Shell. Azure hosts Azure Cloud Shell, an interactive shell 
environment that you can use through your browser. You can use the Bash with Cloud Shell 
to work with Azure services. You can use the Cloud Shell pre-installed commands to run the 
code in this README without having to install anything on your local environment. To start Azure 
Cloud Shell: go to [https://shell.azure.com](https://shell.azure.com), or select the 
Launch Cloud Shell button to open Cloud Shell in your browser.

To run the code in this article in Azure Cloud Shell:

1. Start Cloud Shell.

1. Select the Copy button on a code block to copy the code.

1. Paste the code into the Cloud Shell session by selecting Ctrl+Shift+V on Windows and Linux or by selecting Cmd+Shift+V on macOS.

1. Select Enter to run the code.

## Install the Azure CLI extension

Install the Azure Spring Cloud extension for the Azure CLI using the following command

```bash
    az extension add --name spring-cloud
```
Note - `spring-cloud` CLI extension `2.1.0` or later is a pre-requisite to enable the
latest Java in-process agent for Application Insights. If you already 
have the CLI extension, you may need to upgrade to the latest using --

```bash
    az extension update --name spring-cloud
```

## Clone and build the repo

### Create a new folder and clone the sample app repository to your Azure Cloud account  

```bash
    mkdir source-code
    git clone https://github.com/azure-samples/spring-petclinic-microservices
```

### Change directory and build the project

```bash
    cd spring-petclinic-microservices
    mvn clean package -DskipTests -Denv=cloud
```
This will take a few minutes.

## Unit-1 - Deploy and monitor Spring Boot apps

### Prepare your environment for deployments

Create a bash script with environment variables by making a copy of the supplied template:

```bash
    cp .scripts/setup-env-variables-azure-template.sh .scripts/setup-env-variables-azure.sh
```

Open `.scripts/setup-env-variables-azure.sh` and enter the following information:

```bash

    export SUBSCRIPTION=subscription-id # customize this
    export RESOURCE_GROUP=resource-group-name # customize this
    ...
    export SPRING_CLOUD_SERVICE=azure-spring-cloud-name # customize this
    ...
    export MYSQL_SERVER_NAME=mysql-servername # customize this
    ...
    export MYSQL_SERVER_ADMIN_NAME=admin-name # customize this
    ...
    export MYSQL_SERVER_ADMIN_PASSWORD=SuperS3cr3t # customize this
    ...
```

Then, set the environment:
```bash
    source .scripts/setup-env-variables-azure.sh
```

### Login to Azure 
Login to the Azure CLI and choose your active subscription. Be sure to choose the active subscription that is whitelisted for Azure Spring Cloud

```bash
    az login # --use-device-code , if using  codespaces
    az account list -o table
    az account set --subscription ${SUBSCRIPTION}
```

### Create Azure Spring Cloud service instance
Prepare a name for your Azure Spring Cloud service.  The name must be between 4 and 32 characters long and can contain only lowercase letters, numbers, and hyphens.  The first character of the service name must be a letter and the last character must be either a letter or a number.

Create a resource group to contain your Azure Spring Cloud service.

```bash
    az group create --name ${RESOURCE_GROUP} \
        --location ${REGION}
```

Create an instance of Azure Spring Cloud.

```bash
    az spring-cloud create --name ${SPRING_CLOUD_SERVICE} \
            --sku standard \
            --sampling-rate 100 \
            --resource-group ${RESOURCE_GROUP} \
            --location ${REGION}
```

The service instance will take around five minutes to deploy.

Set your default resource group name and cluster name using the following commands:

```bash
    az configure --defaults \
        group=${RESOURCE_GROUP} \
        location=${REGION} \
        spring-cloud=${SPRING_CLOUD_SERVICE}
```

### Create and configure Log Analytics Workspace

Create a Log Analytics Workspace using Azure CLI:

```bash
    az monitor log-analytics workspace create \
        --workspace-name ${LOG_ANALYTICS} \
        --resource-group ${RESOURCE_GROUP} \
        --location ${REGION}

    export LOG_ANALYTICS_RESOURCE_ID=$(az monitor log-analytics workspace show \
        --resource-group ${RESOURCE_GROUP} \
        --workspace-name ${LOG_ANALYTICS} | jq -r '.id')

    export SPRING_CLOUD_RESOURCE_ID=$(az spring-cloud show \
        --name ${SPRING_CLOUD_SERVICE} \
        --resource-group ${RESOURCE_GROUP} | jq -r '.id')
```

Setup diagnostics and publish logs and metrics from Spring Boot apps to Azure Log Analytics:

```bash
    az monitor diagnostic-settings create --name "send-logs-and-metrics-to-log-analytics" \
        --resource ${SPRING_CLOUD_RESOURCE_ID} \
        --workspace ${LOG_ANALYTICS_RESOURCE_ID} \
        --logs '[
             {
               "category": "ApplicationConsole",
               "enabled": true,
               "retentionPolicy": {
                 "enabled": false,
                 "days": 0
               }
             },
             {
                "category": "SystemLogs",
                "enabled": true,
                "retentionPolicy": {
                  "enabled": false,
                  "days": 0
                }
              },
             {
                "category": "IngressLogs",
                "enabled": true,
                "retentionPolicy": {
                  "enabled": false,
                  "days": 0
                 }
               }
           ]' \
           --metrics '[
             {
               "category": "AllMetrics",
               "enabled": true,
               "retentionPolicy": {
                 "enabled": false,
                 "days": 0
               }
             }
           ]'
```

### Load Spring Cloud Config Server

Use the `application.yml` in the root of this project to load configuration into the Config Server in Azure Spring Cloud.

```bash
    az spring-cloud config-server set \
        --config-file application.yml \
        --name ${SPRING_CLOUD_SERVICE}
```

### Create applications in Azure Spring Cloud

Create 5 apps.

```bash
    az spring-cloud app create --name ${API_GATEWAY} --instance-count 1 --assign-endpoint true \
        --memory 2 \
        --jvm-options='-Xms2048m -Xmx2048m'
    
    az spring-cloud app create --name ${ADMIN_SERVER} --instance-count 1 --assign-endpoint true \
        --memory 2 \
        --jvm-options='-Xms2048m -Xmx2048m'
    
    az spring-cloud app create --name ${CUSTOMERS_SERVICE} --instance-count 1 \
        --memory 2 \
        --jvm-options='-Xms2048m -Xmx2048m'
    
    az spring-cloud app create --name ${VETS_SERVICE} --instance-count 1 \
        --memory 2 \
        --jvm-options='-Xms2048m -Xmx2048m'
    
    az spring-cloud app create --name ${VISITS_SERVICE} --instance-count 1 \
        --memory 2 \
        --jvm-options='-Xms2048m -Xmx2048m'
```

### Create MySQL Database

Create a MySQL database in Azure Database for MySQL.

```bash
    // create mysql server
    az mysql server create --resource-group ${RESOURCE_GROUP} \
     --name ${MYSQL_SERVER_NAME}  --location ${REGION} \
     --admin-user ${MYSQL_SERVER_ADMIN_NAME} \
     --admin-password ${MYSQL_SERVER_ADMIN_PASSWORD} \
     --sku-name GP_Gen5_2 \
     --ssl-enforcement Disabled \
     --version 5.7
    
    // allow access from Azure resources
    az mysql server firewall-rule create --name allAzureIPs \
     --server ${MYSQL_SERVER_NAME} \
     --resource-group ${RESOURCE_GROUP} \
     --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

    export MY_IP=$(curl -s http://whatismyip.akamai.com/)
    
    // allow access from your dev machine for testing
    az mysql server firewall-rule create --name devMachine \
     --server ${MYSQL_SERVER_NAME} \
     --resource-group ${RESOURCE_GROUP} \
     --start-ip-address $MY_IP \
     --end-ip-address $MY_IP
    
    // increase connection timeout
    az mysql server configuration set --name wait_timeout \
     --resource-group ${RESOURCE_GROUP} \
     --server ${MYSQL_SERVER_NAME} --value 2147483
    
    // SUBSTITUTE values
    mysql -u ${MYSQL_SERVER_ADMIN_LOGIN_NAME} \
     -h ${MYSQL_SERVER_FULL_NAME} -P 3306 -p
    
    Enter password:
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 64379
    Server version: 5.6.39.0 MySQL Community Server (GPL)
    
    Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.
    
    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.
    
    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
    
    mysql> CREATE DATABASE petclinic;
    Query OK, 1 row affected (0.10 sec)
    
    mysql> CREATE USER 'root' IDENTIFIED BY 'petclinic';
    Query OK, 0 rows affected (0.11 sec)
    
    mysql> GRANT ALL PRIVILEGES ON petclinic.* TO 'root';
    Query OK, 0 rows affected (1.29 sec)
    
    mysql> CALL mysql.az_load_timezone();
    Query OK, 3179 rows affected, 1 warning (6.34 sec)
    
    mysql> SELECT name FROM mysql.time_zone_name;
    ...
    
    mysql> quit
    Bye
    
    
    az mysql server configuration set --name time_zone \
     --resource-group ${RESOURCE_GROUP} \
     --server ${MYSQL_SERVER_NAME} --value "US/Pacific"
```

### Deploy Spring Boot applications and set environment variables

Deploy Spring Boot applications to Azure.

```bash
    az spring-cloud app deploy --name ${API_GATEWAY} \
        --jar-path ${API_GATEWAY_JAR} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql'
    
    
    az spring-cloud app deploy --name ${ADMIN_SERVER} \
        --jar-path ${ADMIN_SERVER_JAR} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql'
    
    
    az spring-cloud app deploy --name ${CUSTOMERS_SERVICE} \
        --jar-path ${CUSTOMERS_SERVICE_JAR} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql' \
        --env MYSQL_SERVER_FULL_NAME=${MYSQL_SERVER_FULL_NAME} \
              MYSQL_DATABASE_NAME=${MYSQL_DATABASE_NAME} \
              MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_SERVER_ADMIN_LOGIN_NAME} \
              MYSQL_SERVER_ADMIN_PASSWORD=${MYSQL_SERVER_ADMIN_PASSWORD}
    
    
    az spring-cloud app deploy --name ${VETS_SERVICE} \
        --jar-path ${VETS_SERVICE_JAR} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql' \
        --env MYSQL_SERVER_FULL_NAME=${MYSQL_SERVER_FULL_NAME} \
              MYSQL_DATABASE_NAME=${MYSQL_DATABASE_NAME} \
              MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_SERVER_ADMIN_LOGIN_NAME} \
              MYSQL_SERVER_ADMIN_PASSWORD=${MYSQL_SERVER_ADMIN_PASSWORD}
              
    
    az spring-cloud app deploy --name ${VISITS_SERVICE} \
        --jar-path ${VISITS_SERVICE_JAR} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql' \
        --env MYSQL_SERVER_FULL_NAME=${MYSQL_SERVER_FULL_NAME} \
              MYSQL_DATABASE_NAME=${MYSQL_DATABASE_NAME} \
              MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_SERVER_ADMIN_LOGIN_NAME} \
              MYSQL_SERVER_ADMIN_PASSWORD=${MYSQL_SERVER_ADMIN_PASSWORD}
```

```bash
    az spring-cloud app show --name ${API_GATEWAY} | grep url
```

Navigate to the URL provided by the previous command to open the Pet Clinic application.
    
![](./media/petclinic.jpg)

### Monitor Spring Boot applications

#### Use the Petclinic application and make a few REST API calls

Open the Petclinic application and try out a few tasks - view pet owners and their pets, 
vets, and schedule pet visits:

```bash
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/
```

You can also `curl` the REST API exposed by the Petclinic application. The admin REST
API allows you to create/update/remove items in Pet Owners, Pets, Vets and Visits.
You can run the following curl commands:

```bash
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/4
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/ 
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/petTypes
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/3/pets/4
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/6/pets/8/
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/vet/vets
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/visit/owners/6/pets/8/visits
curl -X GET https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/visit/owners/6/pets/8/visits
```

#### Get the log stream for API Gateway and Customers Service

Use the following command to get the latest 100 lines of app console logs from Customers Service. 
```bash
az spring-cloud app logs -n ${CUSTOMERS_SERVICE} --lines 100
```
By adding a `-f` parameter you can get real-time log streaming from the app. Try log streaming for the API Gateway app.
```bash
az spring-cloud app logs -n ${API_GATEWAY} -f
```
You can use `az spring-cloud app logs -h` to explore more parameters and log stream functionalities.

#### Open Actuator endpoints for API Gateway and Customers Service apps

Spring Boot includes a number of additional features to help you monitor and manage your application when you push it to production ([Spring Boot Actuator: Production-ready Features](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#actuator)). You can choose to manage and monitor your application by using HTTP endpoints or with JMX. Auditing, health, and metrics gathering can also be automatically applied to your application.

Actuator endpoints let you monitor and interact with your application. By default, Spring Boot application exposes `health` and `info` endpoints to show arbitrary application info and health information. Apps in this project are pre-configured to expose all the Actuator endpoints.

You can try them out by opening the following app actuator endpoints in a browser:

```bash
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/actuator/
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/actuator/env
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/actuator/configprops

open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator/env
open https://${SPRING_CLOUD_SERVICE}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator/configprops
```

#### Start monitoring Spring Boot apps and dependencies - in Application Insights

Open the Application Insights created by Azure Spring Cloud and start monitoring 
Spring Boot applications. You can find the Application Insights in the same Resource Group where
you created an Azure Spring Cloud service instance.

Navigate to the `Application Map` blade:
![](./media/distributed-tracking-new-ai-agent.jpg)

Navigate to the `Performance` blade:
![](./media/petclinic-microservices-performance.jpg)

Navigate to the `Performance/Dependenices` blade - you can see the performance number for dependencies, 
particularly SQL calls:
![](./media/petclinic-microservices-insights-on-dependencies.jpg)

Click on a SQL call to see the end-to-end transaction in context:
![](./media/petclinic-microservices-end-to-end-transaction-details.jpg)

Navigate to the `Failures/Exceptions` blade - you can see a collection of exceptions:
![](./media/petclinic-microservices-failures-exceptions.jpg)

Click on an exception to see the end-to-end transaction and stacktrace in context:
![](./media/end-to-end-transaction-details.jpg)

Navigate to the `Metrics` blade - you can see metrics contributed by Spring Boot apps, 
Spring Cloud modules, and dependencies. 
The chart below shows `gateway-requests` (Spring Cloud Gateway), `hikaricp_connections`
 (JDBC Connections) and `http_client_requests`.
 
![](./media/petclinic-microservices-metrics.jpg)

Spring Boot registers a lot number of core metrics: JVM, CPU, Tomcat, Logback... 
The Spring Boot auto-configuration enables the instrumentation of requests handled by Spring MVC.
All those three REST controllers `OwnerResource`, `PetResource` and `VisitResource` have been instrumented by the `@Timed` Micrometer annotation at class level.

* `customers-service` application has the following custom metrics enabled:
  * @Timed: `petclinic.owner`
  * @Timed: `petclinic.pet`
* `visits-service` application has the following custom metrics enabled:
  * @Timed: `petclinic.visit`

You can see these custom metrics in the `Metrics` blade:
![](./media/petclinic-microservices-custom-metrics.jpg)

You can use the Availability Test feature in Application Insights and monitor 
the availability of applications:
![](./media/petclinic-microservices-availability.jpg)

Navigate to the `Live Metrics` blade - you can see live metrics on screen with low latencies < 1 second:
![](./media/petclinic-microservices-live-metrics.jpg)

#### Start monitoring Petclinic logs and metrics in Azure Log Analytics

Open the Log Analytics that you created - you can find the Log Analytics in the same 
Resource Group where you created an Azure Spring Cloud service instance.

In the Log Analyics page, selects `Logs` blade and run any of the sample queries supplied below 
for Azure Spring Cloud.

Type and run the following Kusto query to see application logs:
```sql
    AppPlatformLogsforSpring 
    | where TimeGenerated > ago(24h) 
    | limit 500
    | sort by TimeGenerated
```

Type and run the following Kusto query to see `customers-service` application logs:
```sql
    AppPlatformLogsforSpring 
    | where AppName has "customers"
    | limit 500
    | sort by TimeGenerated
```

Type and run the following Kusto query  to see errors and exceptions thrown by each app:
```sql
    AppPlatformLogsforSpring 
    | where Log contains "error" or Log contains "exception"
    | extend FullAppName = strcat(ServiceName, "/", AppName)
    | summarize count_per_app = count() by FullAppName, ServiceName, AppName, _ResourceId
    | sort by count_per_app desc 
    | render piechart
```

Type and run the following Kusto query to see all in the inbound calls into Azure Spring Cloud:
```sql
    AppPlatformIngressLogs
    | project TimeGenerated, RemoteAddr, Host, Request, Status, BodyBytesSent, RequestTime, ReqId, RequestHeaders
    | sort by TimeGenerated
```

Type and run the following Kusto query to see all the logs from the managed Spring Cloud
Config Server managed by Azure Spring Cloud:
```sql
    AppPlatformSystemLogs
    | where LogType contains "ConfigServer"
    | project TimeGenerated, Level, LogType, ServiceName, Log
    | sort by TimeGenerated
```

Type and run the following Kusto query to see all the logs from the managed Spring Cloud
Service Registry managed by Azure Spring Cloud:
```sql
    AppPlatformSystemLogs
    | where LogType contains "ServiceRegistry"
    | project TimeGenerated, Level, LogType, ServiceName, Log
    | sort by TimeGenerated
```

## Unit-2 - Automate deployments using GitHub Actions
### Prerequisites 
To get started with deploying this sample app from GitHub Actions, please:
1. Complete the sections above with your MySQL, Azure Spring Cloud instances and apps created.
2. Fork this repository and turn on GitHub Actions in your fork

### Prepare secrets in your Key Vault
If you do not have a Key Vault yet, run the following commands to provision a Key Vault:
```bash
    az keyvault create --name ${KEY_VAULT} -g ${RESOURCE_GROUP}
```

Add the MySQL secrets to your Key Vault:
```bash
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-SERVER-FULL-NAME" --value ${MYSQL_SERVER_FULL_NAME}
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-DATABASE-NAME" --value ${MYSQL_DATABASE_NAME}
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-SERVER-ADMIN-LOGIN-NAME" --value ${MYSQL_SERVER_ADMIN_LOGIN_NAME}
    az keyvault secret set --vault-name ${KEY_VAULT} --name "MYSQL-SERVER-ADMIN-PASSWORD" --value ${MYSQL_SERVER_ADMIN_PASSWORD}
```

Create a service principle with enough scope/role to manage your Azure Spring Cloud instance:
```bash
    az ad sp create-for-rbac --role contributor --scopes /subscriptions/${SUBSCRIPTION} --sdk-auth
```
With results:
```json
    {
        "clientId": "<GUID>",
        "clientSecret": "<GUID>",
        "subscriptionId": "<GUID>",
        "tenantId": "<GUID>",
        "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
        "resourceManagerEndpointUrl": "https://management.azure.com/",
        "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
        "galleryEndpointUrl": "https://gallery.azure.com/",
        "managementEndpointUrl": "https://management.core.windows.net/"
    }
```
Add them as secrets to your Key Vault:
```bash
    az keyvault secret set --vault-name ${KEY_VAULT} --name "AZURE-CREDENTIALS-FOR-SPRING" --value "<results above>"
```

### Grant access to Key Vault with Service Principal
To generate a key to access the Key Vault, execute command below:
```bash
    az ad sp create-for-rbac --role contributor --scopes /subscriptions/${SUBSCRIPTION}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.KeyVault/vaults/${KEY_VAULT} --sdk-auth
```
Then, follow [the steps here](https://docs.microsoft.com/azure/spring-cloud/spring-cloud-github-actions-key-vault#add-access-policies-for-the-credential) to add access policy for the Service Principal.

In the end, add this service principal as secret named "AZURE_CREDENTIALS" in your forked GitHub repo following [the steps here](https://docs.microsoft.com/azure/spring-cloud/how-to-github-actions?pivots=programming-language-java#set-up-github-repository-and-authenticate-1).

### Customize your workflow
Finally, edit the workflow file `.github/workflows/action.yml` in your forked repo to fill in the subscription ID, Azure Spring Cloud instance name, and Key Vault name that you just created:
```yml
env:
  AZURE_SUBSCRIPTION: subscription-id # customize this
  SPRING_CLOUD_SERVICE: azure-spring-cloud-name # customize this
  KEYVAULT: your-keyvault-name # customize this
```
Once you push this change, you will see GitHub Actions triggered to build and deploy all the apps in the repo to your Azure Spring Cloud instance.
![](./media/automate-deployments-using-github-actions.png)

## Unit-3 - Manage application secrets using Azure KeyVault

Use Azure Key Vault to store and load secrets to connect to MySQL database.

### Create Azure Key Vault and store secrets

If you skipped the [Automation step](#automate-deployments-using-github-actions), create an Azure Key Vault and store database connection secrets.

```bash
    az keyvault create --name ${KEY_VAULT} -g ${RESOURCE_GROUP}
    export KEY_VAULT_URI=$(az keyvault show --name ${KEY_VAULT} | jq -r '.properties.vaultUri')
```

Store database connection secrets in Key Vault.

```bash
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-SERVER-FULL-NAME" --value ${MYSQL_SERVER_FULL_NAME}
        
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-DATABASE-NAME" --value ${MYSQL_DATABASE_NAME}
        
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-SERVER-ADMIN-LOGIN-NAME" --value ${MYSQL_SERVER_ADMIN_LOGIN_NAME}
        
    az keyvault secret set --vault-name ${KEY_VAULT} \
        --name "MYSQL-SERVER-ADMIN-PASSWORD" --value ${MYSQL_SERVER_ADMIN_PASSWORD}
```                      

### Enable Managed Identities for applications in Azure Spring Cloud

Enable System Assigned Identities for applications and export identities to environment.

```bash
    az spring-cloud app identity assign --name ${CUSTOMERS_SERVICE}
    export CUSTOMERS_SERVICE_IDENTITY=$(az spring-cloud app show --name ${CUSTOMERS_SERVICE} | jq -r '.identity.principalId')
    
    az spring-cloud app identity assign --name ${VETS_SERVICE}
    export VETS_SERVICE_IDENTITY=$(az spring-cloud app show --name ${VETS_SERVICE} | jq -r '.identity.principalId')
    
    az spring-cloud app identity assign --name ${VISITS_SERVICE}
    export VISITS_SERVICE_IDENTITY=$(az spring-cloud app show --name ${VISITS_SERVICE} | jq -r '.identity.principalId')
```

### Grant Managed Identities with access to Azure Key Vault

Add an access policy to Azure Key Vault to allow Managed Identities to read secrets.

```bash
    az keyvault set-policy --name ${KEY_VAULT} \
        --object-id ${CUSTOMERS_SERVICE_IDENTITY} --secret-permissions get list
        
    az keyvault set-policy --name ${KEY_VAULT} \
        --object-id ${VETS_SERVICE_IDENTITY} --secret-permissions get list
        
    az keyvault set-policy --name ${KEY_VAULT} \
        --object-id ${VISITS_SERVICE_IDENTITY} --secret-permissions get list
```

### Activate applications to load secrets from Azure Key Vault

Activate applications to load secrets from Azure Key Vault.

```bash
    # DO NOT FORGET to replace the value for "azure.keyvault.uri" JVM startup parameter with your Key Vault URI
    az spring-cloud app update --name ${CUSTOMERS_SERVICE} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql,key-vault -Dazure.keyvault.uri=https://petclinic-keyvault.vault.azure.net/' \
        --env
    
    # DO NOT FORGET to replace the value for "azure.keyvault.uri" JVM startup parameter with your Key Vault URI    
    az spring-cloud app update --name ${VETS_SERVICE} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql,key-vault -Dazure.keyvault.uri=https://petclinic-keyvault.vault.azure.net/' \
        --env
    
    # DO NOT FORGET to replace the value for "azure.keyvault.uri" JVM startup parameter with your Key Vault URI       
    az spring-cloud app update --name ${VISITS_SERVICE} \
        --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql,key-vault -Dazure.keyvault.uri=https://petclinic-keyvault.vault.azure.net/' \
        --env
```

## Next Steps

In this quickstart, you've deployed an existing Spring Boot-based app using Azure CLI, Terraform and GitHub Actions. To learn more about Azure Spring Cloud, go to:

- [Azure Spring Cloud](https://azure.microsoft.com/en-us/services/spring-cloud/)
- [Azure Spring Cloud docs](https://docs.microsoft.com/en-us/azure/java/)
- [Deploy Spring microservices from scratch](https://github.com/microsoft/azure-spring-cloud-training)
- [Deploy existing Spring microservices](https://github.com/Azure-Samples/azure-spring-cloud)
- [Azure for Java Cloud Developers](https://docs.microsoft.com/en-us/azure/java/)
- [Spring Cloud Azure](https://cloud.spring.io/spring-cloud-azure/)
- [Spring Cloud](https://spring.io/projects/spring-cloud)

## Credits

This Spring microservices sample is forked from 
[spring-petclinic/spring-petclinic-microservices](https://github.com/spring-petclinic/spring-petclinic-microservices) - see [Petclinic README](./README-petclinic.md). 

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
