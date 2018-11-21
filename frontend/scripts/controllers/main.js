'use strict';

/**
 * @ngdoc function
 * @name owlDemoApp.controller:FileCtrl
 * @description
 * # fileCtrl
 * Controller of the owlDemoApp
 */


function fileCtrl ($scope) {
     $scope.partialDownloadLink = 'http://162.209.96.234:5000/download?filename=';
     $scope.filename = '';

     $scope.uploadFile = function() {
         $scope.processDropzone();
     };

     $scope.reset = function() {
         $scope.resetDropzone();
     };
 }

angular.module('owlDemoApp')
   .controller('fileCtrl', fileCtrl);

function fileCtrl2 ($scope) {
     $scope.partialDownloadLink = 'http://162.209.96.234:5001/download?filename=';
     $scope.filename = '';

     $scope.uploadFile = function() {
         $scope.processDropzone();
     };

     $scope.reset = function() {
         $scope.resetDropzone();
     };
 }

angular.module('owlDemoApp')
   .controller('fileCtrl2', fileCtrl2);

function fileCtrl3 ($scope) {
     $scope.partialDownloadLink = 'http://162.209.96.234:5002/download?filename=';
     $scope.filename = '';

     $scope.uploadFile = function() {
         $scope.processDropzone();
     };

     $scope.reset = function() {
         $scope.resetDropzone();
     };
 }

angular.module('owlDemoApp')
   .controller('fileCtrl3', fileCtrl3);


angular.module('owlDemoApp')
  .controller('MainCtrl', function () {
    this.awesomeThings = [
      'HTML5 Boilerplate',
      'AngularJS',
      'Karma'
    ];
  });

angular.module('owlDemoApp')
  .controller('SalesController', ['$scope', '$interval', '$http', function($scope, $interval, $http){
    $scope.salesData= [];
    $scope.processed = 0;

    $http.get('http://162.209.96.234:5000/counter')
    //$http.get('http://localhost:5000/counter')
      .then(
        function (data) {
          $scope.processed = data.data;
        },

        function (error){}
      );

    /*
    $scope.$watch('salesData', function() {
        alert('hey, myVar has changed!');
    })
    */
    $scope.$on('clicked-from-directive', function(event, data){
        //console.log("from controller:", data);
        // $scope.salesData = data; --> the source of lag
        $scope.$apply(function() {
          $scope.salesData = data[1];
          $scope.processed = data[0];
        });
    })
    /*
    $interval(function() {
      $scope.salesData.splice(Math.floor(Math.random() *  $scope.salesData.length), 1);
      $scope.salesData.push({
        name: Math.random()
          .toString(36)
          .substring(7),
        value: Math.random()
      });
    }, 1000); */
}]);


angular.module('owlDemoApp')
  .controller('SalesController2', ['$scope', '$interval', '$http', function($scope, $interval, $http){
    $scope.processed = 0;

    $http.get('http://162.209.96.234:5001/counter')
    //$http.get('http://localhost:5001/counter')
      .then(
        function (data) {
          $scope.processed = data.data;
        },
        function (error){}
      );

    $scope.$on('clicked-from-directive2', function(event, data){
      $scope.$apply(function() {
        $scope.processed = data[0];
        $scope.image = data[1];
      });
    });

    $scope.categories = [
       { id: 0, name: "\"Udnie\" by Francis Picabia", url:"images/fs1.jpg"},
       { id: 1, name: "\"The Great Wave off Kanagawa\" by Hokusai", url:"images/fs2.jpg"},
       { id: 2, name: "\"Rain Princess\" by Leonid Afremov", url:"images/fs3.jpg"},
       { id: 3, name: "\"La Muse\" by Picasso", url:"images/fs4.jpg"},
       { id: 4, name: "\"The Scream\" by Edvard Munch", url:"images/fs5.jpg"},
       { id: 5, name: "\"The shipwreck of the Minotaur\" by J. M. W. Turner", url:"images/fs6.jpg"},
    ];

    $scope.itemSelected = $scope.categories[0];

    $scope.onCategoryChange = function () {
        // console.log("Selected Value: " + $scope.itemSelected.id + "\nSelected Text: " + $scope.itemSelected.name);

        $scope.style_img = $scope.itemSelected.url;
        if ($('.dz-image').length > 0) {
          var input_name = $('.dz-image')[0].firstChild['alt'];
          var payload = {
            filename : input_name,
            style : $scope.itemSelected.id
  	      };
          $http({
            method: 'GET',
            url: 'http://162.209.96.234:5001/redraw',
            params: payload})
            .then(
              function mySuccess(response) {
                //console.log(response.data);
                $scope.processed = response.data[0];
                $scope.image = response.data[1];
              },
              function myError(response) {}
            );
        }
    };
}]);



angular.module('owlDemoApp')
  .controller('SalesController3', ['$scope', '$interval', '$http', function($scope, $interval, $http){
    $scope.processed = 0;
    $scope.image = "images/mrcnn_example.jpg";

    $http.get('http://162.209.96.234:5002/counter')
      .then(
        function (data) {
          $scope.processed = data.data;
        },
        function (error){}
      );

    $scope.$on('clicked-from-directive3', function(event, data){
      $scope.$apply(function() {
        $scope.processed = data[0];
        $scope.image = data[1];
      });
    });
}]);



