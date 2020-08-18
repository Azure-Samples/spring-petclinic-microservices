#!/bin/bash
#Expect $RESOURCE_GROUP to be set

export API_GATEWAY=api-gateway
export ADMIN_SERVER=admin-server
export CUSTOMERS_SERVICE=customers-service
export VETS_SERVICE=vets-service
export VISITS_SERVICE=visits-service
MYSQL_DATABASE_NAME=petclinic

az extension add -n spring-cloud -y
SPRING_CLOUD_NAME=$(az spring-cloud list -g "${RESOURCE_GROUP}" -o tsv --query "[].name")

MYSQL_INFO=$(az mysql server list -g ${RESOURCE_GROUP} --query '[0]')
MYSQL_SERVER_NAME=$(echo $MYSQL_INFO | jq -r .name)
MYSQL_USERNAME="$(echo $MYSQL_INFO | jq -r .administratorLogin)@${MYSQL_SERVER_NAME}"
MYSQL_HOST="$(echo $MYSQL_INFO | jq -r .fullyQualifiedDomainName)"


az configure --defaults \
    group=${RESOURCE_GROUP} \
    spring-cloud=${SPRING_CLOUD_NAME}

az spring-cloud config-server set \
    --config-file application.yml \
    --name ${SPRING_CLOUD_NAME} -g "${RESOURCE_GROUP}" 

az spring-cloud app create --name ${API_GATEWAY} --instance-count 1 --is-public true \
    --memory 2 -g "${RESOURCE_GROUP}"  -s "${SPRING_CLOUD_NAME}" \
    --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql'

az spring-cloud app create --name ${ADMIN_SERVER} --instance-count 1 --is-public true \
    -g "${RESOURCE_GROUP}"  -s "${SPRING_CLOUD_NAME}" \
    --memory 2 \
    --jvm-options='-Xms2048m -Xmx2048m  -Dspring.profiles.active=mysql'

az spring-cloud app create --name ${CUSTOMERS_SERVICE} --instance-count 1 \
    -g "${RESOURCE_GROUP}"  -s "${SPRING_CLOUD_NAME}" \
    --memory 2 \
    --jvm-options='-Xms2048m -Xmx2048m  -Dspring.profiles.active=mysql' \
    --env MYSQL_SERVER_FULL_NAME=${MYSQL_HOST} \
        MYSQL_DATABASE_NAME=${MYSQL_DATABASE_NAME} \
        MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_USERNAME} \
        MYSQL_SERVER_ADMIN_PASSWORD="${MYSQL_PASSWORD}"


az spring-cloud app create --name ${VETS_SERVICE} --instance-count 1 \
    -g "${RESOURCE_GROUP}"  -s "${SPRING_CLOUD_NAME}" \
    --memory 2 \
    --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql' \
    --env MYSQL_SERVER_FULL_NAME=${MYSQL_HOST} \
        MYSQL_DATABASE_NAME=${MYSQL_DATABASE_NAME} \
        MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_USERNAME} \
        MYSQL_SERVER_ADMIN_PASSWORD="${MYSQL_PASSWORD}"

az spring-cloud app create --name ${VISITS_SERVICE} --instance-count 1 \
    -g "${RESOURCE_GROUP}"  -s "${SPRING_CLOUD_NAME}" \
    --memory 2 \
    --jvm-options='-Xms2048m -Xmx2048m -Dspring.profiles.active=mysql' \
    --env MYSQL_SERVER_FULL_NAME=${MYSQL_HOST} \
        MYSQL_DATABASE_NAME=${MYSQL_DATABASE_NAME} \
        MYSQL_SERVER_ADMIN_LOGIN_NAME=${MYSQL_USERNAME} \
        MYSQL_SERVER_ADMIN_PASSWORD="${MYSQL_PASSWORD}"



