class GmailCallbacksController < ApplicationController
  before_action :authenticate_user!
  def redirect
    if Rails.env.production?
      client = Signet::OAuth2::Client.new({
        client_id: ENV.fetch('GOOGLE_API_CLIENT_ID_PRODUCTION'),
        client_secret: ENV.fetch('GOOGLE_API_CLIENT_SECRET_PRODUCTION'),
        authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
        scope: Google::Apis::GmailV1::AUTH_GMAIL_READONLY,
        redirect_uri: url_for(action: :callback),
  	  })
    else
      client = Signet::OAuth2::Client.new({
        client_id: ENV.fetch('GOOGLE_API_CLIENT_ID_DEVELOPMENT'),
        client_secret: ENV.fetch('GOOGLE_API_CLIENT_SECRET_DEVELOPMENT'),
        authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
        scope: Google::Apis::GmailV1::AUTH_GMAIL_READONLY,
        redirect_uri: url_for(action: :callback),
      })
    end
	redirect_to client.authorization_uri.to_s
  end

  def callback
    if Rails.env.production?
      client = Signet::OAuth2::Client.new({
        client_id: ENV.fetch('GOOGLE_API_CLIENT_ID_PRODUCTION'),
        client_secret: ENV.fetch('GOOGLE_API_CLIENT_SECRET_PRODUCTION'),
        token_credential_uri: 'https://www.googleapis.com/oauth2/v3/token',
        redirect_uri: url_for(action: :callback),
        code: params[:code]
      })
    else
      client = Signet::OAuth2::Client.new({
        client_id: ENV.fetch('GOOGLE_API_CLIENT_ID_DEVELOPMENT'),
        client_secret: ENV.fetch('GOOGLE_API_CLIENT_SECRET_DEVELOPMENT'),
        token_credential_uri: 'https://www.googleapis.com/oauth2/v3/token',
        redirect_uri: url_for(action: :callback),
        code: params[:code]
      })
    end
    response = client.fetch_access_token!
    session[:access_token] = response['access_token']
    redirect_to url_for(action: :messages)
  end

  def messages
    uri = URI.parse("https://www.googleapis.com/gmail/v1/users/me/messages/")
  	request = Net::HTTP::Get.new(uri)
  	request["Authorization"] = "Bearer #{session[:access_token]}"
  	req_options = {
  	  use_ssl: uri.scheme == "https",
  	}
  	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  	  http.request(request)
  	end
  	@responses = JSON.parse(response.body)["messages"]
  end
end
