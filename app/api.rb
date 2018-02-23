module Piddles
  # Default mounting point for API methods
  class API < Grape::API
    format :json

    before do; end
    after do; end
    helpers do; end

    mount ::Piddles::Ping
    mount ::Piddles::StoreV1
    mount ::Piddles::StoreV2
  end
end
