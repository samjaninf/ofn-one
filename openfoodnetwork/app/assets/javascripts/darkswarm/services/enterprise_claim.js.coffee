Darkswarm.factory 'EnterpriseClaim', ($http, CurrentUser, $rootScope) ->
  EnterpriseClaim = undefined
  new ((EnterpriseClaim = do ->
    `var EnterpriseClaim`

    EnterpriseClaim = ->
      {}
      return

    EnterpriseClaim::enterpriseClaim = ->
      enterprise = undefined
      scope = undefined
      scope = angular.element('#btn_claim').scope()
      scope.user = CurrentUser
      enterprise = scope.enterprise
      if [ CurrentUser.id ][0]
        return $http(
          method: 'POST'
          url: '/enterprise/claim/'
          data:
            user_id: [ CurrentUser.id ][0]
            enterprise_id: enterprise.id)
      return

    EnterpriseClaim
  ))
