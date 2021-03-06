class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # http_basic_authenticate_with name: ENV['BASIC_AUTH_USERNAME'], password: ENV['BASIC_AUTH_PASSWORD'] if Rails.env.production?
  before_action :configure_permitted_parameters, if: :devise_controller?
  PERMISSIBLE_ATTRIBUTES = %i(boss_email slack_url)

  protected
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:account_update, keys: PERMISSIBLE_ATTRIBUTES)
    end
end
