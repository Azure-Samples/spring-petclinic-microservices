'use strict';

angular.module('ownerList')
    .controller('OwnerListController', ['$http', function ($http) {
        var self = this;

        // $http.get('http://customers-service/owners').then(function (resp) {
        $http.get('/api/customer/owners').then(function (resp) {
            self.owners = resp.data;
        });
    }]);
