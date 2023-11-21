'use strict';

angular.module('ownerDetails')
    .controller('OwnerDetailsController', ['$http', '$stateParams', function ($http, $stateParams) {
        var self = this;
        $http.get('/api/customer/owners/' + $stateParams.ownerId).then(function (resp) {
            let owners = resp.data;
            if (owners.pets) {
                owners.pets.forEach(function (pet, index) {
                    $http.get('/api/visit/pets/visits?petId=' + pet.id).then(function (visitResp) {
                        owners.pets[index].visits = visitResp.data.items;
                    });
                });
            } else {
                owners = [];
            }
            self.owner = owners;
        });
    }]);
