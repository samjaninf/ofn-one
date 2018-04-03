class Api::OwnerSerializer < ActiveModel::Serializer
  #cached
  #delegate :cache_key, to: :object

  attributes :id, :email, :login

  def id
    object.id
  end

  def email
    object.email
  end

  def login
    object.login
  end
end

#{
#  "user":
#    {"api_key":null,
#    "bill_address_id":null,
#    "created_at":"2017-10-06T21:45:33-04:00",
#    "email":"admin@admin.com",
#    "enterprise_limit":9999,
#    "id":1,
#    "last_request_at":null,
#    "locale":null,
#    "login":"admin@admin.com",
#    "perishable_token":null,
#    "persistence_token":null,
#    "ship_address_id":null,
#    "spree_api_key":"a825788336fe4512ac34d961cdf42eb396384d69d51517d5",
#    "updated_at":"2017-10-15T18:03:05-04:00"
#  }
#  
#}