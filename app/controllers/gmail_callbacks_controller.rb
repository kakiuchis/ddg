class GmailCallbacksController < ApplicationController
  before_action :authenticate_user!
  include GmailCallbacksHelper

  def redirect
    if Rails.env.production?
      client = Signet::OAuth2::Client.new(
        client_id: ENV['GOOGLE_API_CLIENT_ID_PRODUCTION'],
        client_secret: ENV['GOOGLE_API_CLIENT_SECRET_PRODUCTION'],
  	  )
    else
      client = Signet::OAuth2::Client.new(
        client_id: ENV['GOOGLE_API_CLIENT_ID_DEVELOPMENT'],
        client_secret: ENV['GOOGLE_API_CLIENT_SECRET_DEVELOPMENT'],
      )
    end
    client.authorization_uri = 'https://accounts.google.com/o/oauth2/auth'
    client.scope = Google::Apis::GmailV1::AUTH_GMAIL_READONLY
    client.redirect_uri = url_for(action: :callback)
	  redirect_to client.authorization_uri.to_s
  end

  def callback
    if Rails.env.production?
      client = Signet::OAuth2::Client.new(
        client_id: ENV['GOOGLE_API_CLIENT_ID_PRODUCTION'],
        client_secret: ENV['GOOGLE_API_CLIENT_SECRET_PRODUCTION'],
      )
    else
      client = Signet::OAuth2::Client.new(
        client_id: ENV['GOOGLE_API_CLIENT_ID_DEVELOPMENT'],
        client_secret: ENV['GOOGLE_API_CLIENT_SECRET_DEVELOPMENT'],
      )
    end
    client.token_credential_uri = 'https://www.googleapis.com/oauth2/v3/token'
    client.redirect_uri = url_for(action: :callback)
    client.code = params[:code]
    response = client.fetch_access_token!
    session[:access_token] = response['access_token']
    redirect_to url_for(action: :messages)
  end


  def messages
    token = session[:access_token]
    # query = "from:kakiuchi@itpm-gk.com to:kakiuchis@gmail.com"
    query = ""
    messages = get_messages(token, query)["messages"]
    
    @bodies = []
    messages.first(20).each do |message|
      if get_message(token, message["id"])["payload"]["parts"].present?
        body = get_message(token, message["id"])["payload"]["parts"][1]["body"]["data"]
        body = clean_body(body)
      else
        body = get_message(token, message["id"])["snippet"]
      end
      @bodies.push(body)
    end
  end
end
