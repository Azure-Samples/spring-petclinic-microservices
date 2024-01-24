#!/bin/bash

set -Eeuo pipefail

# Fail fast the deployment if envs are empty
if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "The subscription Id is not successfully retrieved, please retry another deployment." >&2
  exit 1
fi

if [[ -z "$RESOURCE_GROUP" ]]; then
  echo "The resource group is not successfully retrieved, please retry another deployment." >&2
  exit 1
fi

if [[ -z "$ASA_SERVICE_NAME" ]]; then
  echo "The Azure Spring Apps service name is not successfully retrieved, please retry another deployment." >&2
  exit 1
fi

declare -A app_module_path_map
declare -a artifact_arr=("customers-service" "vets-service" "visits-service")
app_module_path_map[${artifact_arr[0]}]="spring-petclinic-customers-service"
app_module_path_map[${artifact_arr[1]}]="spring-petclinic-vets-service"
app_module_path_map[${artifact_arr[2]}]="spring-petclinic-visits-service"

az extension add --name spring --upgrade
git clone https://github.com/Azure-Samples/spring-petclinic-microservices.git
cd spring-petclinic-microservices

deployJavaCode() {
  config_file_pattern="application,$1"
  az spring application-configuration-service bind --subscription $SUBSCRIPTION_ID --resource-group $RESOURCE_GROUP --service $ASA_SERVICE_NAME --app $1
  az spring service-registry bind --subscription $SUBSCRIPTION_ID --resource-group $RESOURCE_GROUP --service $ASA_SERVICE_NAME --app $1
  az spring app deploy --subscription $SUBSCRIPTION_ID --resource-group $RESOURCE_GROUP --service $ASA_SERVICE_NAME --name $1 --source-path --config-file-pattern $config_file_pattern --build-env BP_MAVEN_BUILT_MODULE=${app_module_path_map[$1]} BP_JVM_VERSION=17
}

deployFrontendCode() {
  az spring app deploy --subscription $SUBSCRIPTION_ID --resource-group $RESOURCE_GROUP --service $ASA_SERVICE_NAME --name frontend --build-env BP_WEB_SERVER=nginx --source-path ./spring-petclinic-frontend
}

for item in "${artifact_arr[@]}"
do
  deployJavaCode "$item" &
done

deployFrontendCode &

jobs_count=$(jobs -p | wc -l)

# Loop until all jobs are done
while [ "$jobs_count" -gt 0 ]; do
  wait -n
  exit_status=$?

  if [ $exit_status -ne 0 ]; then
    echo "One of the deployment failed with exit status $exit_status"
    exit $exit_status
  else
    jobs_count=$((jobs_count - 1))
  fi
done

echo "Deployed to Azure Spring Apps successfully."

# Delete uami generated before exiting the script
az identity delete --ids ${AZ_SCRIPTS_USER_ASSIGNED_IDENTITY}
