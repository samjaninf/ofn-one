Darkswarm.controller "MapCtrl", ($scope, MapConfiguration, OfnMap, EnterpriseClaim, AuthenticationService, SpreeUser, CurrentUser)->
  $scope.OfnMap = OfnMap
  $scope.map = angular.copy MapConfiguration.options
  $scope.spree_user = CurrentUser
  