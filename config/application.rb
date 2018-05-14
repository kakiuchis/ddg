require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ddg
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.autoload_paths += %W(#{config.root}/lib)
    config.active_job.queue_adapter = :delayed_job

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'localhost:3000', 'ddgfb.herokuapp.com'
        resource '*', headers: :any, methods: [:get, :post, :options]
      end
    end

    config.action_dispatch.default_headers = {
	  'Access-Control-Allow-Credentials' => 'true',
	  'Access-Control-Allow-Origin' => 'http://localhost:3000',
	  'Access-Control-Request-Method' => '*'
	}
  end
end
