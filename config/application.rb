puts "Running in #{ENV['RACK_ENV']} environment =>"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'api'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'models'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'app/helpers'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'boot'

Bundler.require :default, ENV['RACK_ENV']
Dir[File.expand_path('../../api/**/*.rb', __FILE__)].each { |f| require f }
Dir[File.expand_path('../../lib/**/*.rb', __FILE__)].each { |f| require f }

require 'app'
require 'api'

# In a perfect world, this would all be done with a proper JSON or YAML config
# file. Today, we're just going to put these names directly into code and call
# it good.
V!_TESTER = :piddles
V2_TESTERS = %w(piddles puddles pyddles)

HydrantQueueV1 = Hydrant::Queue.new(V2_TESTERS)
