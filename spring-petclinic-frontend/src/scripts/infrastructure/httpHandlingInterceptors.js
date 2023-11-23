'use strict';

/**
 * Global HTTP interceptor handlers.
 */
const CUSTOMERS_SERVICE_API_URL_PREFIX = '/api/customer';
const VETS_SERVICE_API_URL_PREFIX = '/api/vet';
const VISITS_SERVICE_API_URL_PREFIX = '/api/visit';

angular.module('infrastructure')
    .factory('httpHandlingInterceptors',
        function () {
        return {
            request: function(config) {
                if (process.env.NODE_ENV === 'production') {
                    if (config.url.includes(CUSTOMERS_SERVICE_API_URL_PREFIX)) {
                        config.url = process.env.CUSTOMERS_SERVICE + config.url.substring(CUSTOMERS_SERVICE_API_URL_PREFIX.length);
                    } else if (config.url.includes(VETS_SERVICE_API_URL_PREFIX)) {
                        config.url = process.env.VETS_SERVICE + config.url.substring(VETS_SERVICE_API_URL_PREFIX.length);
                    } else if (config.url.includes(VISITS_SERVICE_API_URL_PREFIX)) {
                        config.url = process.env.VISITS_SERVICE + config.url.substring(VISITS_SERVICE_API_URL_PREFIX.length);
                    }
                }
                return config;
            },
            responseError: function (response) {
                var error = response.data;
                alert(error.error + "\r\n" + error.errors.map(function (e) {
                    return e.field + ": " + e.defaultMessage;
                }).join("\r\n"));
                return response;
            }
        }
    });
