class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google
    @user = User.find_for_google_oauth(request.env["omniauth.auth"])
    if @user.persisted?
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.google_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url
    end
  end
end