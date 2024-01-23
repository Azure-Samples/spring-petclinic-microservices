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

version="3.0.1"
auth_header="no-auth"
base_url="https://github.com/Azure-Samples/spring-petclinic-microservices/releases/download"
#source_code_url="https://github.com/Azure-Samples/spring-petclinic-microservices/archive/refs/tags/v$version.zip"
source_code_url="https://github.com/moarychan/spring-petclinic-microservices/archive/refs/tags/v$version.zip"
declare -a artifact_arr=("customers-service" "vets-service" "visits-service")

az extension add --name spring --upgrade

deployJar() {
  jar_file_name="$1-$version.jar"
  source_url="$base_url/v$version/$jar_file_name"
  # Download binary
  echo "Downloading binary from $source_url to $jar_file_name"
  if [ "$auth_header" == "no-auth" ]; then
      curl -L "$source_url" -o $jar_file_name
  else
      curl -H "Authorization: $auth_header" "$source_url" -o $jar_file_name
  fi

  config_file_pattern="application,$1"
  az spring application-configuration-service bind --subscription $SUBSCRIPTION_ID --resource-group $RESOURCE_GROUP --service $ASA_SERVICE_NAME --app $1
  az spring service-registry bind --subscription $SUBSCRIPTION_ID --resource-group $RESOURCE_GROUP --service $ASA_SERVICE_NAME --app $1
  az spring app deploy --subscription $SUBSCRIPTION_ID --resource-group $RESOURCE_GROUP --service $ASA_SERVICE_NAME --name $1 --artifact-path $jar_file_name --config-file-pattern $config_file_pattern
}

deployFrontend() {
  project_name="spring-petclinic-microservices"
  zip_file_name="$project_name-$version"
  zip_file="$project_name-$version.zip"
  # Download binary
  echo "Downloading binary from $source_code_url to $zip_file"
  if [ "$auth_header" == "no-auth" ]; then
      curl -L "$source_code_url" -o $zip_file
  else
      curl -H "Authorization: $auth_header" "$source_code_url" -o $zip_file
  fi

  unzip $zip_file
  cd $zip_file_name
  az spring app deploy --subscription $SUBSCRIPTION_ID --resource-group $RESOURCE_GROUP --service $ASA_SERVICE_NAME --name frontend --build-env BP_WEB_SERVER=nginx --source-path ./spring-petclinic-frontend
}

for item in "${artifact_arr[@]}"
do
  deployJar $item &
done

deployFrontend &

jobs_count=$(jobs -p | wc -l)

# Loop until all jobs are done
while [ $jobs_count -gt 0 ]; do
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
