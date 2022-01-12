package org.springframework.samples.petclinic.visits.web;

import java.io.IOException;
import java.util.function.Consumer;
import java.util.function.Supplier;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.core.annotation.Order;
import org.springframework.messaging.Message;
import org.springframework.messaging.support.GenericMessage;
import org.springframework.samples.petclinic.visits.model.Visit;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.gson.Gson;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import lombok.extern.slf4j.Slf4j;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

@Component
@Order(1)
@Slf4j
public class APIResponseFilter implements Filter {
	
	@Autowired
    private Sinks.Many<Message<String>> many;

	@Override
	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
			throws IOException, ServletException {
		// TODO Auto-generated method stub
		
		// do nothing
		HttpServletRequest req = (HttpServletRequest) request;
		HttpServletResponse res = (HttpServletResponse) response;
		
		log.info("Logging Request  {} : {}", req.getMethod(), req.getRequestURI());
		
		Data data = new Data();
		data.setMethod(req.getMethod());
		data.setRequestURI(req.getRequestURI());
		
		log.info("Logging Request in json {} ", data.toString());
		
		many.emitNext(new GenericMessage<>(data.toString()), Sinks.EmitFailureHandler.FAIL_FAST);
		
		chain.doFilter(request, response);
		log.info("Logging Response :{}", res.getContentType());		
		
	}
	
    @Bean
    public Sinks.Many<Message<String>> many() {
        return Sinks.many().unicast().onBackpressureBuffer();
    }

    @Bean
    public Supplier<Flux<Message<String>>> supply(Sinks.Many<Message<String>> many) {
        return () -> many.asFlux()
                         .doOnNext(m -> log.info("Manually sending message {}", m))
                         .doOnError(t -> log.error("Error encountered", t));
    }    
    
	@Override
	public void init(FilterConfig filterConfig) throws ServletException {
		// TODO Auto-generated method stub
		log.info("Initiaizing {} ", this.getClass().getName());
		Filter.super.init(filterConfig);
	}

	@Override
	public void destroy() {
		// TODO Auto-generated method stub
		log.info("Destroying {} ", this.getClass().getName());;
		Filter.super.destroy();
	}
	
	@Getter @Setter @NoArgsConstructor
	class Data{
		String method;
		String requestURI;

		@Override
		public String toString() {
			ObjectMapper mapper = new ObjectMapper();
            try {
				return mapper.writeValueAsString(this);
			} catch (JsonProcessingException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
            return null;
		}
	}

}
