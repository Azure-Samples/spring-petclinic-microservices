#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

echo "Packaging apps"
./mvnw clean package -DskipTests

pkill -9 -f spring-petclinic || echo "Failed to kill any apps"

echo "Running apps"
mkdir -p target
nohup java -jar spring-petclinic-config-server/target/*.jar > target/config-server.log 2>&1 &
echo "Waiting for config server to start"
sleep 20
nohup java -jar spring-petclinic-discovery-server/target/*.jar > target/discovery-server.log 2>&1 &
echo "Waiting for discovery server to start"
sleep 20
nohup java -jar spring-petclinic-customers-service/target/*.jar > target/customers-service.log 2>&1 &
nohup java -jar spring-petclinic-visits-service/target/*.jar > target/visits-service.log 2>&1 &
nohup java -jar spring-petclinic-vets-service/target/*.jar > target/vets-service.log 2>&1 &
nohup java -jar spring-petclinic-api-gateway/target/*.jar > target/api-gateway.log 2>&1 &
nohup java -jar spring-petclinic-admin-server/target/*.jar > target/admin-server.log 2>&1 &
echo "Waiting for apps to start"
sleep 60
