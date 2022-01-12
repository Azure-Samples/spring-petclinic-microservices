package org.springframework.samples.petclinic.visits.web;

import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FilterConfig {

    // uncomment this and comment the @Component in the filter class definition to register only for a url pattern
    // @Bean
    public FilterRegistrationBean<APIResponseFilter> loggingFilter() {
        FilterRegistrationBean<APIResponseFilter> registrationBean = new FilterRegistrationBean<>();

        registrationBean.setFilter(new APIResponseFilter());
	    registrationBean.addUrlPatterns("/pets/*");
	    registrationBean.addUrlPatterns("/owners/*");
        //registrationBean.addUrlPatterns("/*");
        
        registrationBean.setOrder(2);

        return registrationBean;

    }

}