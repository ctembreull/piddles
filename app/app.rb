module Piddles
  # Default runnable for Rack
  class App
    def initialize; end

    # TODO: replace MyApp with your module structure
    def self.instance
      @instance ||= Rack::Builder.new(debug: true) do
        run Piddles::App.new
      end.to_app
    end

    # TODO: replace MyApp with your module structure
    def call(env)
      Piddles::API.call(env)
    end
  end
end
