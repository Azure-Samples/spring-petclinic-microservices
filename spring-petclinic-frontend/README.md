# Frontend for PetClinic project

This module is the frontend part of the PetClinic project, it provides the same features as the `spring-petclinic-api-gateway` module.
When deploying to Azure Spring Apps enterprise plan, you can use the managed component Spring Cloud Gateway on Azure Spring Apps, which is more efficient and cost-effective. 

## Run locally

Please note that supporting services (Config and Discovery Server) must be started before any other application.

Enter the project root directory and open a terminal to start Config Server:

```shell
./mvnw spring-boot:run -pl spring-petclinic-config-server
```

Open a new terminal to start Discovery Server:

```shell
./mvnw spring-boot:run -pl spring-petclinic-discovery-server
```

For Customers, Vets, and Visits services, open new terminal in turn and execute the following commands:

```shell
./mvnw spring-boot:run -pl spring-petclinic-customers-service
./mvnw spring-boot:run -pl spring-petclinic-vets-service
./mvnw spring-boot:run -pl spring-petclinic-visits-service
```

For Gateway service, it's required to enable the Spring profile `deployment` to enable the static resource proxy, open a new terminal and execute the following command:

```shell
./mvnw spring-boot:run -Dspring-boot.run.profiles=default,development -pl spring-petclinic-api-gateway
```

Install [Node.js 16.20 LTS](https://nodejs.org/en/download/) if you don't have it already.

Enter the project `spring-petclinic-frontend` directory and open a new terminal to install dependencies and run the frontend:

```shell
npm install
npm run start
````

If everything goes well, you can access the PetClinic at given location:
* Gateway - http://localhost:8080
