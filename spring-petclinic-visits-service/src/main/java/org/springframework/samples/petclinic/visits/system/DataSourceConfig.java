/*
 * Copyright 2002-2017 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.springframework.samples.petclinic.visits.system;

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import com.azure.identity.DefaultAzureCredentialBuilder;
import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.SecretClientBuilder;
import com.azure.security.keyvault.secrets.models.KeyVaultSecret;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

/**
 * Cache could be disable in unit test.
 * 
 * @author Maciej Szarlinski
 */
@Configuration
@ComponentScan
class DataSourceConfig {

	final static HikariConfig dsConfig = new HikariConfig();

	static {
		dsConfig.addDataSourceProperty("cachePrepStmts", "true");
		dsConfig.addDataSourceProperty("prepStmtCacheSize", "250");
		dsConfig.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
	}

	@Value("${spring.datasource.url}")
	private String url;

	@Value("${spring.datasource.username}")
	private String username;

	@Bean
	@Primary
	@ConfigurationProperties("spring.datasource")
	public DataSourceProperties dataSourceProperties() {
		return new DataSourceProperties();
	}

	@Bean
	public DataSource dataSource() {
		DataSourceProperties dsProps = dataSourceProperties();

		String uri = System.getenv("KEYVAULT_URI");
		String secreteName = getSecretName(dsProps.getPassword());
		SecretClient secretClient = new SecretClientBuilder().vaultUrl(uri)
				.credential(new DefaultAzureCredentialBuilder().build()).buildClient();

		KeyVaultSecret retrievedSecret = secretClient.getSecret(secreteName);
		dsProps.setPassword(retrievedSecret.getValue());

//		return dsProps.initializeDataSourceBuilder()
//				.build();

		dsConfig.setJdbcUrl(url);
		dsConfig.setUsername(username);
		dsConfig.setPassword(retrievedSecret.getValue());
		HikariDataSource ds = new HikariDataSource(dsConfig);
		return ds;

	}

	public String getSecretName(String value) {

		if (value == null || (value = value.trim()).length() < 1)
			throw new IllegalArgumentException("Invalid secrete name, null, white space or zero length string");

		int pos = value.indexOf("secret-name:");
		if (pos < -0)
			throw new IllegalArgumentException("Invalid secrete name format, <secret-name:{your secret name}>");

		return value.substring(pos + "secret-name:".length(), value.length() - 1);

	}

}
