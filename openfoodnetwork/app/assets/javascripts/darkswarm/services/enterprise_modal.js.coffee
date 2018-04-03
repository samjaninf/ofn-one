Darkswarm.factory "EnterpriseModal", ($modal, EnterpriseClaim, CurrentUser, $rootScope)->
  # Build a modal popup for an enterprise.
  new class EnterpriseModal
    open: (enterprise)->
      scope = $rootScope.$new(true) # Spawn an isolate to contain the enterprise
      scope.enterprise = enterprise
      scope.spree_user = CurrentUser
      $modal.open(templateUrl: "enterprise_modal.html", scope: scope)

      
