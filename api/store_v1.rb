require 'hydrant'

module Piddles
  class StoreV1 < Grape::API
    version 'v1', using: :path
    format :json

    namespace :store do

      get :availability do
        begin
          {available: Hydrant.can_sell_hydrant}
        rescue Exception => ex
          # Do something to log this
          error!({error: "An error occurred with our store. Please contact support."}, 500)
        end
      end

      post :purchase do
        begin
          {success: Hydrant.sell_hydrant}
        rescue Exception => ex
          error!({error: "An error occurred with our store. Please contact support."}, 500)
        end
      end

    end

  end
end
