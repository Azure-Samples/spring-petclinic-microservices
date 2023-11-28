'use strict';

require('bootstrap/dist/css/bootstrap.min.css');
require("./less/petclinic.less");
require("jquery");
require('bootstrap/dist/js/bootstrap.min');
import * as angular from 'angular';
require('angular-ui-router/release/angular-ui-router.min');

import './scripts/infrastructure/infrastructure';
import './scripts/infrastructure/httpErrorHandlingInterceptor';

import './scripts/owner-list/owner-list';
import './scripts/owner-list/owner-list.component';
import './scripts/owner-list/owner-list.controller';

import './scripts/owner-details/owner-details';
import './scripts/owner-details/owner-details.component';
import './scripts/owner-details/owner-details.controller';

import './scripts/owner-form/owner-form';
import './scripts/owner-form/owner-form.component';
import './scripts/owner-form/owner-form.controller';

import './scripts/pet-form/pet-form';
import './scripts/pet-form/pet-form.component';
import './scripts/pet-form/pet-form.controller';

import './scripts/pet-form/pet-form';
import './scripts/pet-form/pet-form.component';
import './scripts/pet-form/pet-form.controller';

import './scripts/visits/visits';
import './scripts/visits/visits.component';
import './scripts/visits/visits.controller';

import './scripts/vet-list/vet-list';
import './scripts/vet-list/vet-list.component';
import './scripts/vet-list/vet-list.controller';

/* App Module */
var petClinicApp = angular.module('petClinicApp', [
    'ui.router', 'infrastructure', 'layoutNav', 'layoutFooter', 'layoutWelcome',
    'ownerList', 'ownerDetails', 'ownerForm', 'petForm', 'visits', 'vetList']);

petClinicApp.config(['$stateProvider', '$urlRouterProvider', '$locationProvider', '$httpProvider', function(
    $stateProvider, $urlRouterProvider, $locationProvider, $httpProvider) {

    // safari turns to be lazy sending the Cache-Control header
    $httpProvider.defaults.headers.common["Cache-Control"] = 'no-cache';
    $httpProvider.interceptors.push('HttpErrorHandlingInterceptor');

    $locationProvider.hashPrefix('!');

    $urlRouterProvider.otherwise('/welcome');
    $stateProvider
        .state('app', {
            abstract: true,
            url: '',
            template: '<ui-view></ui-view>'
        })
        .state('welcome', {
            parent: 'app',
            url: '/welcome',
            template: '<layout-welcome></layout-welcome>'
        });
}]);

['welcome', 'nav', 'footer'].forEach(function(c) {
    var mod = 'layout' + c.toUpperCase().substring(0, 1) + c.substring(1);
    angular.module(mod, []);
    angular.module(mod).component(mod, {
        templateUrl: "scripts/fragments/" + c + ".html"
    });
});
