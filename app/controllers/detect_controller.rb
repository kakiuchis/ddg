class DetectController < ApplicationController
  before_action :authenticate_user!
  include GmailCallbacksHelper
  include DetectHelper

  def redirect
    session[:einstein_token] = params["einstein_token"]
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
    google_token = session[:access_token]
    einstein_token = session[:einstein_token]
    query = "from:kakiuchi@itpm-gk.com to:kakiuchis@gmail.com newer_than:4h"
    messages = get_messages(google_token, query)["messages"]
    model_id = Learn.user_choice_one_newer(current_user).modelId
    
    @analysises = []
    @hash = Hash.new { |h,k| h[k] = {} }
    i = 0

    messages.reverse.each do |message|
      message_info = get_message_info(google_token, message["id"])
      if message_info["payload"]["parts"].present?
        body = message_info["payload"]["parts"][1]["body"]["data"]
      else
        body = message_info["payload"]["body"]["data"]
      end

      body = clean_body(body)
      body_en = translate(body)

      analysis = analysis(einstein_token, model_id, body_en)
      @analysises.push(analysis)
      if analysis["probabilities"][0]["label"] == "danger"
      	danger_probability = analysis["probabilities"][0]["probability"]
        message_info["payload"]["headers"].count.times do |i|
          if message_info["payload"]["headers"][i]["name"] == "Date"
            @date = message_info["payload"]["headers"][i]["value"]
            break
          end
          if message_info["payload"]["headers"][i]["name"] == "Subject"
            @subject = message_info["payload"]["headers"][i]["value"]
            break
          end
        end
        url = "https://mail.google.com/mail/u/0/#all/#{message["id"]}"
        
        text = "危険度#{danger_probability*100}%\n【日時】#{@date}\n【件名】#{@subject}\n【本文】#{body}\n#{url}"
        slack_annnounce(text, ENV['WEBHOOK_URL'])

        @hash[i]["body"] = body
        @hash[i]["bodies_en"] = body_en
        @hash[i]["danger_probability"] = danger_probability
        @hash[i]["date"] = @date
        @hash[i]["subjects"] = @subject
        @hash[i]["url"] = url
        @hash[i]["text"] = text
        i = i + 1
      end
    end
  end
end
