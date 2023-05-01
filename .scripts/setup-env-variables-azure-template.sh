#!/usr/bin/env bash

# ==== Resource Group ====
export SUBSCRIPTION=subscription-id # customize this
export RESOURCE_GROUP=rg-petclinic # customize this
export REGION=eastus # customize this

# ==== Service and App Instances ====
export SPRING_CLOUD_SERVICE=asa-petclinic # customize this
export API_GATEWAY=api-gateway
export ADMIN_SERVER=admin-server
export CUSTOMERS_SERVICE=customers-service
export VETS_SERVICE=vets-service
export VISITS_SERVICE=visits-service

# ==== JARS ====
springboot_version=3.0.6
export API_GATEWAY_JAR=spring-petclinic-api-gateway/target/spring-petclinic-api-gateway-${springboot_version}.jar
export ADMIN_SERVER_JAR=spring-petclinic-admin-server/target/spring-petclinic-admin-server-${springboot_version}.jar
export CUSTOMERS_SERVICE_JAR=spring-petclinic-customers-service/target/spring-petclinic-customers-service-${springboot_version}.jar
export VETS_SERVICE_JAR=spring-petclinic-vets-service/target/spring-petclinic-vets-service-${springboot_version}.jar
export VISITS_SERVICE_JAR=spring-petclinic-visits-service/target/spring-petclinic-visits-service-${springboot_version}.jar

# ==== DIRs ==== (for ja_JP)
export API_GATEWAY_DIR=spring-petclinic-api-gateway
export ADMIN_SERVER_DIR=spring-petclinic-admin-server
export CUSTOMERS_SERVICE_DIR=spring-petclinic-customers-service
export VETS_SERVICE_DIR=spring-petclinic-vets-service
export VISITS_SERVICE_DIR=spring-petclinic-visits-service

# ==== MYSQL INFO ====
export MYSQL_SERVER_NAME=mysql-petclinic # customize this
export MYSQL_SERVER_FULL_NAME=${MYSQL_SERVER_NAME}.mysql.database.azure.com
export MYSQL_SERVER_ADMIN_NAME=azureuser # customize this
export MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_SERVER_ADMIN_NAME}\@${MYSQL_SERVER_NAME}
export MYSQL_SERVER_ADMIN_PASSWORD=SuperS3cr3t # customize this
export MYSQL_DATABASE_NAME=petclinic
export MYSQL_IDENTITY=mysql-identity

# ==== KEY VAULT Info ====
export KEY_VAULT=your-keyvault-name # customize this

# ==== LOG ANALYTICS Info ====
export LOG_ANALYTICS=${SPRING_CLOUD_SERVICE}
