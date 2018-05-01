class CustomAuthenticationFailure < Devise::FailureApp
  protected
  def redirect_url
    user_google_omniauth_authorize_path
  end
end