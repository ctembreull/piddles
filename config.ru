require 'rack/cors'
require 'guard-rack'
require File.expand_path('../config/environment', __FILE__)

use Rack::Cors do
  @debug_mode = false
  allow do
    origins '*'
    resource '*',
             methods: [:get, :post, :put, :delete, :options],
             headers: ['Authorization', 'Content-Type', 'Accept']
  end
end

# TODO: Replace MyApp with your module structure
run Piddles::App.instance
