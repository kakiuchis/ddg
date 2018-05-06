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
    redirect_to url_for(action: :uptake)
  end


  def uptake
    token = session[:access_token]
    query = "from:kakiuchi@itpm-gk.com to:kakiuchis@gmail.com"
    messages = get_messages(token, query)["messages"]
    
    @bodies = []
    @subjects = []
    messages.first(6).reverse.each do |message|
      message_info = get_message_info(token, message["id"])
      if message_info["payload"]["parts"].present?
        body = message_info["payload"]["parts"][1]["body"]["data"]
      else
        body = message_info["payload"]["body"]["data"]
      end
      body = clean_body(body)
      # body_en = translate(body)

      message_info["payload"]["headers"].count.times do |i|
        if message_info["payload"]["headers"][i]["name"] == "Subject"
          @subject = message_info["payload"]["headers"][i]["value"]
          break
        end
      end
      @bodies.push(body)
      @subjects.push(@subject)

      Message.create(
        message_id: message["id"],
        user_id: current_user.id,
        title:  @subject,
        body:  body,
        # body_en: body_en,
        )
    end
  end
end
