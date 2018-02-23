ENV['RACK_ENV'] ||= 'test'

require 'rubygems'
require 'rack/test'

require File.expand_path("../../config/environment", __FILE__)
# If using factory_girl, uncomment the next line
# Dir[File.expand_path("../../spec/factories/*.rb", __FILE__)].each {|f| require f}

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.fail_fast = true
  config.mock_with :rspec
  config.expect_with :rspec

  config.before :suite do
    # begin
    # ensure
    # end
  end

end
