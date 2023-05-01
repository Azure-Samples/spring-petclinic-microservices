---
page_type: sample
languages:
- java
products:
- Azure Spring Apps
description: "Deploy Spring Boot apps using Azure Spring Apps and MySQL"
urlFragment: "spring-petclinic-microservices"
---

# MySQLを使うSpring BootアプリをAzure Spring Appsにデプロイする

Azure Spring Appsを使うと、Azure上でSpring Bootアプリケーションを簡単に実行できます。

このクイックスタートでは、既存のJava Spring CloudアプリケーションをAzureにデプロイする方法を説明します。終了後は、Azure CLIでアプリケーションの管理を継続しても、Azure Portalを使用しての管理に切り替えることも可能です。

* [MySQLを使うSpring BootアプリをAzure Spring Appsにデプロイする](#MySQLを使うSpring-BootアプリをAzure-Spring-Appsにデプロイする)
  * [このクイックスタートを終了すると](#このクイックスタートを終了すると)
  * [必要なもの](#必要なもの)
  * [Azure CLI拡張のインストール](#Azure-CLI拡張のインストール)
  * [リポジトリのクローン](#リポジトリのクローン)
  * [Unit 1 - Spring Bootアプリのデプロイと監視](#unit-1---Spring-Bootアプリのデプロイと監視)
  * [Unit 2 - GitHub Actionsを使ったデプロイの自動化](#unit-2---GitHub-Actionsを使ったデプロイの自動化)
  * [Unit 3 - Azure Spring AppsのアプリケーションのManaged Identitiesを有効化](#unit-3---Azure-Spring-AppsのアプリケーションのManaged-Identitiesを有効化)
  * [さらに学ぶのであれば](#さらに学ぶのであれば)

## このクイックスタートを終了すると

このクイックスタートでは以下のことを体験できます。
- 既存のSpring Bootアプリケーションのビルド
- Azure Spring Apps サービスインスタンスのプロビジョニング
  > Terraformがお好みの場合は、Terraformを使ったプロビジョニングも可能です。[`README-terraform`](./terraform/README-terraform.md) を参照してください。
- アプリケーションをAzureにデプロイ
- Azure AD認証を使用してAzure Database for MySQLにアプリケーションを接続
- アプリケーションの実行
- アプリケーションの監視
- GitHub Actionsを使ったデプロイの自動化
- Azure KeyVaultを利用したアプリケーションシークレットの管理

## 必要なもの

Javaアプリをクラウドにデプロイするためには、Azureのサブスクリプションが必要です。Azureサブスクリプションをまだお持ちでない場合は、[MSDNサブスクライバー特典](https://azure.microsoft.com/pricing/member-offers/msdn-benefits-details/)を有効にするか、[無料のAzureアカウント]((https://azure.microsoft.com/free/)) にサインアップしてください。

さらに、以下のものが必要です。

| [Azure CLI version 2.44.0 以上](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest) 
| [Java 17](https://learn.microsoft.com/en-us/java/openjdk/download#openjdk-17) 
| [Maven](https://maven.apache.org/download.cgi) 
| [Git](https://git-scm.com/)
|

> 注意 - Bash シェルを使ってください。Azure CLI はすべての環境で同じように動作するはずですが、シェルのセマンティクスはさまざまです。したがって、このレポのコマンドで使用できるのは bash だけです。
Windows でこれらのレポの手順を完了するには、Windows ディストリビューションに付属している Git Bash を使用することもできますが、resource IDなど、先頭に `/` がある場合、ファイルパスと誤認識して補完する場合があるので、以下の環境変数を設定しておいてください。

```bash
    export MSYS_NO_PATHCONV=1
```

### Azure Cloud Shellの利用

または、Azure Cloud Shellを使用することもできます。Azureでは、ブラウザから使用できる対話型のシェル環境であるAzure Cloud Shellを用意しています。Cloud ShellでBashを使い、Azureサービスを操作できます。ローカル環境に何もインストールしなくても、Cloud Shellにプリインストールされているコマンドを使って、このREADMEのコードを実行できます。Azure Cloud Shellを起動するには [https://shell.azure.com](https://shell.azure.com) にアクセスするか、Launch Cloud Shellボタンを選択して、ブラウザでCloud Shellを開いてください。

Azure Cloud Shellで本記事のコードを実行するには

1. Cloud Shellを起動

1. コードブロックのコピーボタンを選択し、コードをコピー

1. Windows と Linux では Ctrl+Shift+V を、macOS では Cmd+Shift+V を選択し、コードを Cloud Shell セッションに貼り付け

1. Enterを選択して、コードを実行

## Azure CLI拡張のインストール

以下のコマンドを使用して、Azure CLI Azure Spring拡張をインストールします。

```bash
    az extension add --name spring
```
注意 - Application Insights の最新の Java プロセス内エージェントを有効にするには、`spring` CLI extension `1.5.0` 以降が必要です。すでにCLI拡張をお持ちの場合は、以下のコマンドを使って最新のものにアップグレードする必要がある場合があります。

```bash
    az extension update --name spring
```

## リポジトリのクローン

新規ディレクトリを作成し、サンプルアプリのリポジトリをAzure Cloudアカウントにクローンします。

```bash
    mkdir source-code
    git clone https://github.com/azure-samples/spring-petclinic-microservices
```

クローンした先のディレクトリに移動し、プロジェクトをビルドしておきます。

```bash
    cd spring-petclinic-microservices
    mvn clean package -DskipTests
```
少々時間がかかります。

## Unit 1 - Spring Bootアプリのデプロイと監視

### デプロイのための環境の準備

テンプレートをコピーし、環境変数を持つBashスクリプトを作成します。

```bash
    cp .scripts/setup-env-variables-azure-template.sh .scripts/setup-env-variables-azure.sh
```

`.scripts/setup-env-variables-azure.sh` を開いて、以下の情報を設定します。

```bash
    export SUBSCRIPTION=subscription-id # customize this
    export RESOURCE_GROUP=resource-group-name # customize this
    ...
    export SPRING_APPS=azure-spring-cloud-name # customize this
    ...
    export MYSQL_SERVER_NAME=mysql-servername # customize this
    ...
    export MYSQL_SERVER_ADMIN_NAME=admin-name # customize this
    ...
    export MYSQL_SERVER_ADMIN_PASSWORD=SuperS3cr3t # customize this
    ...
```

入力が完了したら保存し、環境に設定します。

```bash
    source .scripts/setup-env-variables-azure.sh
```

### Azureへのログイン

Login to the Azure CLIにログインし、アクティブなサブスクリプションを選択します。アクティブなサブスクリプションではAzure Spring Appsが利用できるようになっていることを確認しておいてください。

```bash
    az login
    az account list -o table
    az account set --subscription ${SUBSCRIPTION}
```

### Azure Spring Appのインスタンスを作成

Prepare a name for your Azure Spring Appインスタンスの名前を準備します。命名規則は以下の通りです。

- 4文字以上、32文字以内
- アルファベットの小文字、数字、ハイフンのみを含む
- 名前の先頭文字はアルファベット
- 名前の末尾文字はアルファベットまたは数字

リソースグループを作成し、Azure Spring Appsをその中に作成します。

```bash
    az group create --name ${RESOURCE_GROUP} \
        --location ${REGION}
```

Azure Spring Appのインスタンスを作成します。

```bash
    az spring create --name ${SPRING_APPS} \
            --sku standard \
            --sampling-rate 100 \
            --resource-group ${RESOURCE_GROUP} \
            --location ${REGION}
```

このインスタンスの作成完了までおよそ5分かかります。

デフォルトのリソースグループ、クラスター名、リージョンを以下のコマンドで設定します。

```bash
    az configure --defaults \
        group=${RESOURCE_GROUP} \
        location=${REGION} \
        spring=${SPRING_APPS}
```

### Log Analytics Workspaceの作成と設定

以下のAzure CLIコマンドでLog Analytics Workspaceを作成します。

```bash
    az monitor log-analytics workspace create \
        --workspace-name ${LOG_ANALYTICS} \
        --resource-group ${RESOURCE_GROUP} \
        --location ${REGION}

    export LOG_ANALYTICS_RESOURCE_ID=$(az monitor log-analytics workspace show \
        --resource-group ${RESOURCE_GROUP} \
        --workspace-name ${LOG_ANALYTICS} \
        --query 'id' \
        --output tsv)

    export SPRING_APPS_RESOURCE_ID=$(az spring show \
        --name ${SPRING_APPS} \
        --resource-group ${RESOURCE_GROUP} \
        --query 'id' \
        --output tsv)
```

診断設定を構成します。Spring Bootアプリからのとログ、メトリックのパブリッシュ先として、Azure Log Analytics Workspaceを指定します。

```bash
    az monitor diagnostic-settings create \
        --name "send-logs-and-metrics-to-log-analytics" \
        --resource ${SPRING_APPS_RESOURCE_ID} \
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

### Spring Apps Config Serverへのロード

このプロジェクトのルートにある `application.yml` を使って、Azure Spring AppsのConfig Serverに構成情報をロードします。

```bash
    az spring config-server set \
        --config-file application.yml \
        --name ${SPRING_APPS}
```

### Azure Spring Appsでのアプリケーションの作成

5個のアプリケーションを作成します。

```bash
    az spring app create --name ${API_GATEWAY} --instance-count 1 --assign-endpoint true \
        --memory 3Gi \
        --runtime-version Java_17 \
        --jvm-options='-XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6'
    
    az spring app create --name ${ADMIN_SERVER} --instance-count 1 --assign-endpoint true \
        --memory 3Gi \
        --runtime-version Java_17 \
        --jvm-options='-XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6'
    
    az spring app create --name ${CUSTOMERS_SERVICE} --instance-count 1 \
        --memory 3Gi \
        --runtime-version Java_17 \
        --jvm-options='-XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6'
    
    az spring app create --name ${VETS_SERVICE} --instance-count 1 \
        --memory 3Gi \
        --runtime-version Java_17 \
        --jvm-options='-XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6'
    
    az spring app create --name ${VISITS_SERVICE} --instance-count 1 \
        --memory 3Gi \
        --runtime-version Java_17 \
        --jvm-options='-XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6'
```

### MySQL Databaseの作成

Azure Database for MySQL Flexible ServerにMySQL Databaseを作成します。

```bash
    # MySQL Serverを作成し、Azureリソースからのアクセスを許可する (Versionはお好みで)
    az mysql flexible-server create \
        --name ${MYSQL_SERVER_NAME} \
        --resource-group ${RESOURCE_GROUP} \
        --location ${REGION} \
        --admin-user ${MYSQL_SERVER_ADMIN_NAME}  \
        --admin-password ${MYSQL_SERVER_ADMIN_PASSWORD} \
        --public-access 0.0.0.0 \
        --tier Burstable \
        --sku-name Standard_B1ms \
        --storage-size 32 \
        --version 8.0.21
    
    # テスト目的でのアクセスを許可するため、開発マシンのPublic IPを許可
    MY_IP=$(curl http://whatismyip.akamai.com)
    az mysql flexible-server firewall-rule create \
            --resource-group ${RESOURCE_GROUP} \
            --name ${MYSQL_SERVER_NAME} \
            --rule-name devMachine \
            --start-ip-address ${MY_IP} \
            --end-ip-address ${MY_IP}
    
    # データベースの作成
    az mysql flexible-server db create \
            --resource-group ${RESOURCE_GROUP} \
            --server-name ${MYSQL_SERVER_NAME} \
            --database-name ${MYSQL_DATABASE_NAME}
    
    # 接続タイムアウト時間の延長
    az mysql flexible-server parameter set \
        --resource-group ${RESOURCE_GROUP} \
        --server ${MYSQL_SERVER_NAME} \
        --name wait_timeout \
        --value 2147483
    
    # タイムゾーンの設定（オプション）   
    az mysql flexible-server parameter set \
        --resource-group ${RESOURCE_GROUP} \
        --server ${MYSQL_SERVER_NAME} \
        --name time_zone \
        --value "Asia/Tokyo"
    
    # MySQL用Mangaed identityを作成し、このIdentityをMySQL Serverに割り当て、Azure AD認証を有効化します
    az identity create \
        --name ${MYSQL_IDENTITY} \
        --resource-group ${RESOURCE_GROUP} \
        --location ${REGION}

    IDENTITY_ID=$(az identity show --name ${MYSQL_IDENTITY} --resource-group ${RESOURCE_GROUP} --query id -o tsv)

    # Service Connectorの作成 1) Customers service
    az spring connection create mysql-flexible \
        --resource-group ${RESOURCE_GROUP} \
        --service ${SPRING_APPS} \
        --app ${CUSTOMERS_SERVICE} \
        --deployment default \
        --tg ${RESOURCE_GROUP} \
        --server ${MYSQL_SERVER_NAME} \
        --database ${MYSQL_DATABASE_NAME} \
        --system-identity mysql-identity-id=$IDENTITY_ID \
        --client-type springboot \
        --connection customers_service

    # Service Connectorの作成 2) Vets service
    az spring connection create mysql-flexible \
        --resource-group ${RESOURCE_GROUP} \
        --service ${SPRING_APPS} \
        --app ${VETS_SERVICE} \
        --deployment default \
        --tg ${RESOURCE_GROUP} \
        --server ${MYSQL_SERVER_NAME} \
        --database ${MYSQL_DATABASE_NAME} \
        --system-identity mysql-identity-id=$IDENTITY_ID \
        --client-type springboot \
        --connection vets_service
    
    # Service Connectorの作成 3) Visits service
    az spring connection create mysql-flexible \
        --resource-group ${RESOURCE_GROUP} \
        --service ${SPRING_APPS} \
        --app ${VISITS_SERVICE} \
        --deployment default \
        --tg ${RESOURCE_GROUP} \
        --server ${MYSQL_SERVER_NAME} \
        --database ${MYSQL_DATABASE_NAME} \
        --system-identity mysql-identity-id=$IDENTITY_ID \
        --client-type springboot \
        --connection visits_service
```

### Spring Bootアプリケーションのデプロイおよび環境変数の設定

Spring BootアプリケーションをAzureにデプロイします。
JARファイルを作成後、`--artifact-path`オプションを指定してデプロイすることも可能ですが、今回は、事前にJARファイルを作成せず、 `--source-path` オプションを指定してソースファイルをアップロードし、Buildpackを使ってビルドすることにします。

```bash
az spring app deploy \
        --resource-group ${RESOURCE_GROUP} \
        --service ${SPRING_APPS} \
        --name ${API_GATEWAY} \
        --source-path \
        --jvm-options="-XX:+UseG1GC -XX:+UseStringDeduplication -XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6 -XX:ActiveProcessorCount=1" \
        --env SPRING_PROFILES_ACTIVE=passwordless BP_JVM_VERSION=17 \
        --target-module spring-petclinic-api-gateway

az spring app deploy \
        --resource-group ${RESOURCE_GROUP} \
        --service ${SPRING_APPS} \
        --name ${ADMIN_SERVER} \
        --source-path \
        --jvm-options="-XX:+UseG1GC -XX:+UseStringDeduplication -XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6 -XX:ActiveProcessorCount=1" \
        --env SPRING_PROFILES_ACTIVE=passwordless BP_JVM_VERSION=17 \
        --target-module spring-petclinic-admin-server

az spring app deploy \
        --resource-group ${RESOURCE_GROUP} \
        --service ${SPRING_APPS} \
        --name ${CUSTOMERS_SERVICE} \
        --source-path \
        --jvm-options="-XX:+UseG1GC -XX:+UseStringDeduplication -XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6 -XX:ActiveProcessorCount=1" \
        --env SPRING_PROFILES_ACTIVE=passwordless BP_JVM_VERSION=17 \
        --target-module spring-petclinic-customers-service

az spring app deploy \
        --resource-group ${RESOURCE_GROUP} \
        --service ${SPRING_APPS} \
        --name ${VETS_SERVICE} \
        --source-path \
        --jvm-options="-XX:+UseG1GC -XX:+UseStringDeduplication -XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6 -XX:ActiveProcessorCount=1" \
        --env SPRING_PROFILES_ACTIVE=passwordless BP_JVM_VERSION=17 \
        --target-module spring-petclinic-vets-service

az spring app deploy \
        --resource-group ${RESOURCE_GROUP} \
        --service ${SPRING_APPS} \
        --name ${VISITS_SERVICE} \
        --source-path \
        --jvm-options="-XX:+UseG1GC -XX:+UseStringDeduplication -XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6 -XX:ActiveProcessorCount=1" \
        --env SPRING_PROFILES_ACTIVE=passwordless BP_JVM_VERSION=17 \
        --target-module spring-petclinic-visits-service
```

完了したら、以下のコマンドでAPI GatewayのURLを確認してください。

```bash
    echo $(az spring app show --name ${API_GATEWAY} --query properties.url --output tsv)
```

上記コマンドで取得したAPI GatewayのURLをブラウザで開くと、Petclinicアプリケーションにアクセスできるはずです。
    
![](./media/petclinic.jpg)

### Spring Bootアプリケーションの監視

#### Petclinicアプリを使い、REST APIを呼び出す

Open the Petclinicアプリケーションを開いて、ペットオーナーやペット、獣医師、来院の予約を確認します。

```bash
open https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/
```

`curl` でPetclinicアプリケーションが公開しているREST APIを呼び出すこともできます。管理用REST APIを使って、ペットオーナー、ペット、獣医師、来院予約を作成・更新・削除できます。
以下のcurlコマンドを実行できます。

```bash
curl -X GET https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners
curl -X GET https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/4
curl -X GET https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/ 
curl -X GET https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/customer/petTypes
curl -X GET https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/3/pets/4
curl -X GET https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/customer/owners/6/pets/8/
curl -X GET https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/vet/vets
curl -X GET https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/visit/owners/6/pets/8/visits
curl -X GET https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/visit/owners/6/pets/8/visits
```

#### API GatewayとCustomer Serviceのログストリームを確認

以下のコマンドを使って、Customer Serviceから出力されたアプリケーションコンソールログのうち、最新の100行を表示します。

```bash
az spring app logs -n ${CUSTOMERS_SERVICE} --lines 100
```

`-f` パラメータを追加すると、アプリケーションからのリアルタイム・ログストリームを確認できます。API Gatewayアプリケーションのログストリームを確認してみましょう。

```bash
az spring app logs -n ${API_GATEWAY} -f
```

`az spring app logs -h` を利用すると、パラメータやログストリーム機能の詳細を確認できます。

#### API GatewayとCustomer Serviceの両アプリのActuatorエンドポイントをオープンする

Spring Bootには、本運用環境にアプリケーションをデプロイした際のアプリケーションの監視・管理に役立つ数多くの追加機能([Spring Boot Actuator: Production-ready Features](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#actuator))が含まれています。アプリケーションの管理・監視は、HTTPエンドポイントまたはJMXを選択できます。また、監査、ヘルス、メトリクス収集を、アプリケーションに自動的に適用できます。

Actuatorエンドポイントを使うと、アプリケーションの監視および対話が可能です。デフォルトでは、Spring Bootアプリケーションは `health` と `info` エンドポイントを公開し、任意のアプリケーション情報とヘルス情報を表示します。このプロジェクトのアプリケーションは、すべてのActuatorエンドポイントを公開するようにあらかじめ設定済みです。

以下で示すアプリのActuatorエンドポイントをブラウザで開いて確認できます。

```bash
echo https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/actuator/
echo https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/actuator/env
echo https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/actuator/configprops

echo https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator
echo https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator/env
echo https://${SPRING_APPS}-${API_GATEWAY}.azuremicroservices.io/api/customer/actuator/configprops
```

#### Application Insightsを使った、Spring Bootアプリとその依存関係の監視

Azure Spring Appsで作成したApplication Insightsを開き、Spring Bootアプリケーションの監視を開始します。
アプリケーションインサイトは、Azure Spring Appsのサービスインスタンスを作成したリソースグループと同じリソースグループにあります。

`Application Map` ブレード
![](./media/distributed-tracking-new-ai-agent.jpg)

`Performance` ブレード
![](./media/petclinic-microservices-performance.jpg)

`Performance/Dependencies` ブレード

依存関係に関するパフォーマンスに関する数値を確認できます。オレンジで囲んだ部分はSQL呼び出しのパフォーマンスです。
![](./media/petclinic-microservices-insights-on-dependencies.jpg)

Click on a SQL呼び出しをクリックすると、コンテキストのEnd to Endのトランザクションを確認できます。
![](./media/petclinic-microservices-end-to-end-transaction-details.jpg)

`Failures/Exceptions`ブレード

例外のコレクションを確認できます。
![](./media/petclinic-microservices-failures-exceptions.jpg)

例外をクリックすると、コンテキストのEnd to Endのトランザクションならびにスタックトレースを確認できます。
![](./media/end-to-end-transaction-details.jpg)

`Metrics` ブレード

Spring Bootアプリが提供するメトリクス、Spring Cloudのモジュール、および依存関係を確認できます。
下図では、`gateway-requests` (Spring Cloud Gateway)、`hikaricp_connections` (JDBC接続) と`http_client_requests` が確認できます。
![](./media/petclinic-microservices-metrics.jpg)

Spring Bootでは、JVM、CPU、Tomcat、Logbackなどの多くのコアメトリクスが登録されています。
Spring Bootの自動設定により、Spring MVCが処理するリクエストのインスツルメンテーションが可能になります。
`OwnerResource`、`PetResource`、`VisitResource` というこの3つのRESTコントローラは、クラスレベルの `@Timed` Micrometerアノテーションによってインストルメンテーションされています。

* `customers-service` アプリケーションでは、以下のカスタムメトリクスが有効化されています。
  * @Timed: `petclinic.owner`
  * @Timed: `petclinic.pet`
* `visits-service` アプリケーションでは、以下のカスタムメトリクスが有効化されています。
  * @Timed: `petclinic.visit`

`Metrics` ブレードでこれらのカスタムメトリクスを確認できます。
![](./media/petclinic-microservices-custom-metrics.jpg)

Application Insightsの可用性テスト機能を利用し、アプリケーションの可用性を監視できます。
![](./media/petclinic-microservices-availability.jpg)

`Live Metrics` ブレード

1秒以下の低レイテンシでライブメトリクスを確認できます。
![](./media/petclinic-microservices-live-metrics.jpg)

#### Azure Log AnalyticsでPetClinicのログとメトリクスを監視する

Azure Spring Appsインスタンスと同じリソースグループに作成したLog Analytics Workspaceを開きます。

Log Analyicsのページで、`Logs` ブレードをクリックし、以下のAzure Spring Apps用のサンプルクエリを実行します。

以下のKustoクエリを実行し、アプリケーションログを確認します。

```sql
    AppPlatformLogsforSpring 
    | where TimeGenerated > ago(24h) 
    | limit 500
    | sort by TimeGenerated
```

以下のKustoクエリを実行し、 `customers-service` アプリケーションログを確認します。

```sql
    AppPlatformLogsforSpring 
    | where AppName has "customers"
    | limit 500
    | sort by TimeGenerated
```

以下のKustoクエリを実行し、各アプリケーションがスローした例外やエラーを確認します。

```sql
    AppPlatformLogsforSpring 
    | where Log contains "error" or Log contains "exception"
    | extend FullAppName = strcat(ServiceName, "/", AppName)
    | summarize count_per_app = count() by FullAppName, ServiceName, AppName, _ResourceId
    | sort by count_per_app desc 
    | render piechart
```

以下のKustoクエリを実行し、Azure Spring Appsに対するすべてのインバウンドリクエストを確認します。

```sql
    AppPlatformIngressLogs
    | project TimeGenerated, RemoteAddr, Host, Request, Status, BodyBytesSent, RequestTime, ReqId, RequestHeaders
    | sort by TimeGenerated
```

以下のKustoクエリを実行し、Azure Spring Appsが管理するマネージドSpring Cloud Config Serverからのすべてのログを確認します。

```sql
    AppPlatformSystemLogs
    | where LogType contains "ConfigServer"
    | project TimeGenerated, Level, LogType, ServiceName, Log
    | sort by TimeGenerated
```

以下のKustoクエリを実行し、Azure Spring Appsが管理するマネージドSpring Cloud Service Registryからのすべてのログを確認します。

```sql
    AppPlatformSystemLogs
    | where LogType contains "ServiceRegistry"
    | project TimeGenerated, Level, LogType, ServiceName, Log
    | sort by TimeGenerated
```

## Unit-2 - GitHub Actionsを使ったデプロイの自動化

### 前提条件

このUnitは、事前に以下が終了している必要があります。

1. MySQL、Azure Spring Appsインスタンス、アプリを作成した状態で、Unit 1を完了していること。
2. このリポジトリをフォークし、フォーク先でGitHub Actionsを有効にしていること。

### GitHubのFederated Credentialsの準備

[ここ](https://learn.microsoft.com/azure/developer/github/connect-from-azure) に記載の手順で、Azure Active DirectoryにGitHub Federated Credentialsを作成できます。

Azure Active Directoryアプリケーションを作成します。以下では`github-petclinic-actions`という名前のアプリケーションを作成していますが、できればユニークになるような名前にすることを強く推奨します。

```bash
AZURE_CLIENT_ID=$(az ad app create --display-name github-petclinic-actions --query appId --output tsv)
GITHUB_OBJECTID=$(az ad app show --id $AZURE_CLIENT_ID --query id --output tsv)
```

アプリケーションのservice principalを作成します。

```bash
ASSIGNEE_OBJECTID=$(az ad sp create --id $AZURE_CLIENT_ID --query id --output tsv)
```

Azure Spring Appsインスタンスを管理するのに十分なスコープとロールを持つサービスプリンシパルを作成します。以下の例では、インフラストラクチャをホストするリソースグループにcontributor (共同管理者) ロールを割り当てています。

```bash
az role assignment create \
  --role contributor \
  --subscription ${SUBSCRIPTION} \
  --assignee-object-id  ${ASSIGNEE_OBJECTID} \
  --assignee-principal-type ServicePrincipal \
  --scope /subscriptions/${SUBSCRIPTION}/resourceGroups/${RESOURCE_GROUP}
```

Azure ADにGitHubのfederated credentialsを追加します。

```bash
az rest --method POST \
  --uri 'https://graph.microsoft.com/beta/applications/<GITHUB_OBJECTID>/federatedIdentityCredentials' \
  --body '{"name":"<CREDENTIAL-NAME>","issuer":"https://token.actions.githubusercontent.com","subject":"repo:<OWNER>/spring-petclinic-microservices:ref:refs/heads/azure","description":"チュートリアル","audiences":["api://AzureADTokenExchange"]}'
```

上記コマンドで置き換える値は以下の通りです。
| Item | Description |
|---|----|
|GITHUB_OBJECTID|前のステップで作成したサービスプリンシパルのオブジェクトID |
|CREDENTIAL-NAME|クレデンシャルの名前。Azure ADポータルに表示される名前 |
|OWNER|コードをホストしている GitHub リポジトリの所有者。リポジトリをフォークした場合、オーナーはGitHubのユーザー名。 |

```bash
az rest --method POST --uri 'https://graph.microsoft.com/beta/applications/00000000-0000-0000-0000-000000000000/federatedIdentityCredentials' --body '{"name":"github-petclinic-actions","issuer":"https://token.actions.githubusercontent.com","subject":"repo:Azure-Samples/spring-petclinic-microservices:ref:refs/heads/azure","description":"チュートリアル","audiences":["api://AzureADTokenExchange"]}'
```

コマンド実行結果は以下のようになるはずです。

```bash
{
  "@odata.context": "https://graph.microsoft.com/beta/$metadata#applications('000000000-0000-0000-0000-000000000000')/federatedIdentityCredentials/$entity",
  "audiences": [
    "api://AzureADTokenExchange"
  ],
  "description": "チュートリアル",
  "id": "000000000-0000-0000-0000-000000000000",
  "issuer": "https://token.actions.githubusercontent.com",
  "name": "github-petclinic-actions",
  "subject": "repo:Azure-Samples/spring-petclinic-microservices:ref:refs/heads/azure"
}
```

Azure Portalから見ると以下のようになっているはずです。
![Federated Credentials](./media/azuread-github-federated-credential.png)

> 注意: Azure ADポータルでfederated credentialsを更新するのに数分かかる場合があります。

### GitHubシークレットの準備

actionsでは以下のシークレットをGitHubリポジトリに保存されていることを想定しています。

| Item | Description |
|---|----|
|AZURE_TENANT_ID|Azure Spring AppsインスタンスをホストしているAzureサブスクリプションのテナントID|
|AZURE_SUBSCRIPTION_ID|Azure Spring AppsインスタンスをホストしているAzureサブスクリプションのサブスクリプションID|
|AZURE_CLIENT_ID|前のステップで作成したAzure ADアプリケーションのクライアントID|
|RESOURCE_GROUP|Azure Spring Appsインスタンスをホストしているリソースグループ|
|SPRING_APPS_SERVICE_NAME|Azure Spring Appsインスタンスの名前|

見ての通り、誰かがアクセスしても何もできないので、本当の機密値は存在しません。これらの値は環境変数で置換できます。

GitHub Actionsが起動し、リポジトリにあるすべてのアプリをビルドしてAzure Spring Appsのインスタンスにデプロイするのを確認しましょう。

![](./media/automate-deployments-using-github-actions.png)

## Unit-3 - Azure Spring AppsのアプリケーションのManaged Identitiesを有効化

このUnitは、すでにService Connectorで有効化されているので、実施不要です。

システム割り当てのManaged Identityを各アプリケーションで有効化し、各Managed IdentityのPrincipal IDを環境変数に設定します。

```bash
    az spring app identity assign --name ${CUSTOMERS_SERVICE}
    export CUSTOMERS_SERVICE_IDENTITY=$(az spring app show --name ${CUSTOMERS_SERVICE} --query 'identity.principalId' --output tsv)
    
    az spring app identity assign --name ${VETS_SERVICE}
    export VETS_SERVICE_IDENTITY=$(az spring app show --name ${VETS_SERVICE} --query 'identity.principalId' --output tsv)
    
    az spring app identity assign --name ${VISITS_SERVICE}
    export VISITS_SERVICE_IDENTITY=$(az spring app show --name ${VISITS_SERVICE} --query 'identity.principalId' --output tsv)
```

### MySQLへのパスワードレス接続を使うようにアプリケーションを構成する

MySQLにパスワードレス接続するためのプロファイルが構成リポジトリにあります。有効化するには、 `SPRING_PROFILES_ACTIVE=passwordless` という環境変数を各アプリケーションで設定する必要があります。

```bash
    az spring app update --name ${CUSTOMERS_SERVICE} \
        --jvm-options='-XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6' \
        --env SPRING_PROFILES_ACTIVE=passwordless

    az spring app update --name ${VETS_SERVICE} \
        --jvm-options='-XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6' \
        --env SPRING_PROFILES_ACTIVE=passwordless
        
    az spring app update --name ${VISITS_SERVICE} \
        --jvm-options='-XX:InitialRAMPercentage=50.0 -XX:MinRAMPercentage=66.6 -XX:MaxRAMPercentage=66.6' \
        --env SPRING_PROFILES_ACTIVE=passwordless
```

## さらに学ぶのであれば

このクイックスタートでは、Azure CLI、Terraform、GitHub Actionsを使って、既存のSpring Bootベースのアプリをデプロイしました。Azure Spring Appsの詳細を学ぶには、以下を参照してください。

- [Azure Spring Apps](https://azure.microsoft.com/products/spring-apps/)
- [Azure Spring Apps docs](https://learn.microsoft.com/azure/developer/java/)
- [Deploy Spring microservices from scratch](https://github.com/microsoft/azure-spring-cloud-training)
- [Deploy existing Spring microservices](https://github.com/Azure-Samples/azure-spring-cloud)
- [Azure for Java Cloud Developers](https://learn.microsoft.com/azure/developer/java/)
- [Spring Cloud Azure](https://spring.io/projects/spring-cloud-azure)
- [Spring Cloud](https://spring.io/projects/spring-cloud)

## Credits

このSpringマイクロサービスのサンプルは
[spring-petclinic/spring-petclinic-microservices](https://github.com/spring-petclinic/spring-petclinic-microservices)からフォークしたものです。詳細は [Petclinic README](./README-petclinic.md) をご覧ください。

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
