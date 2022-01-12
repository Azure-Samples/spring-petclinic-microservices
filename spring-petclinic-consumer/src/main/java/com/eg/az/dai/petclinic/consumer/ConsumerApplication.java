package com.eg.az.dai.petclinic.consumer;

import java.util.function.Consumer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.annotation.Bean;
import org.springframework.integration.annotation.ServiceActivator;
import org.springframework.messaging.Message;

import com.azure.spring.integration.core.EventHubHeaders;
import com.azure.spring.integration.core.api.reactor.Checkpointer;
import static com.azure.spring.integration.core.AzureHeaders.CHECKPOINTER;  

import lombok.extern.slf4j.Slf4j;

@EnableDiscoveryClient
@SpringBootApplication
@Slf4j
public class ConsumerApplication {

	public static void main(String[] args) {
		// TODO Auto-generated method stub
		SpringApplication.run(ConsumerApplication.class, args);
	}

	@Bean
	public Consumer<Message<String>> consume() {
//		return message -> log.info("**New message received: '{}'", message.getPayload());
		
		//EventHubMessageConverter conv = new EventHubMessageConverter();		
		return message -> {
			Checkpointer checkpointer = (Checkpointer) message.getHeaders().get(CHECKPOINTER);
			log.info(
					"**New message received: '{}', partition key: {}, sequence number: {}, offset: {}, enqueued time: {}",
					message.getPayload(), message.getHeaders().get(EventHubHeaders.PARTITION_KEY),
					message.getHeaders().get(EventHubHeaders.SEQUENCE_NUMBER),
					message.getHeaders().get(EventHubHeaders.OFFSET),
					message.getHeaders().get(EventHubHeaders.ENQUEUED_TIME));
			
			log.info("**Message Class: {}", message.getClass().getName());
			
			if(checkpointer != null)
				checkpointer.success()
						.doOnSuccess(success -> {
							onSuccess(message);
							log.info("**Message '{}' successfully checkpointed", message.getPayload());
						})
						.doOnError(error -> {
							log.error("**Exception found", error);
						}).subscribe();
		};
		
	}
	
	private Object onSuccess(Message<String> message) {
		// TODO Auto-generated method stub
		//	Do something on success
		
		//	business logic here
		
		log.info("**Done");
		
		return true;
	} 	

//    // Replace destination with spring.cloud.stream.bindings.consume-in-0.destination
//    // Replace group with spring.cloud.stream.bindings.consume-in-0.group
//    @ServiceActivator(inputChannel = "{spring.cloud.stream.bindings.consume-in-0.destination}.{spring.cloud.stream.bindings.consume-in-0.group}.errors")
//    public void consumerError(Message<?> message) {
//        log.error("**Handling customer ERROR: " + message);
//    }
//
//    // Replace destination with spring.cloud.stream.bindings.supply-out-0.destination
//    @ServiceActivator(inputChannel = "{spring.cloud.stream.bindings.supply-out-0.destination}.errors")
//    public void producerError(Message<?> message) {
//        log.error("**Handling Producer ERROR: " + message);
//    }		
	
}
