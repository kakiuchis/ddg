class DetectController < ApplicationController
  before_action :authenticate_user!
  include GmailCallbacksHelper
  include DetectHelper

  def redirect
    session[:einstein_token] = params["einstein_token"]
    session[:newer_than_hour] = params["newer_than_hour"]

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
    newer_than_hour = session[:newer_than_hour]
    query = "from:#{current_user.boss_email} to:#{current_user.email} newer_than:#{newer_than_hour}h"
    model_id = Learn.user_choice_one_newer(current_user).modelId
    @analysises = []
    i = 0
    
    ## get messages
    messages = get_messages(google_token, query)["messages"]
    messages = [] if messages == nil
    
    messages.reverse.each do |message|
      message_info = get_message_info(google_token, message["id"])

      ## get body
      if message_info["payload"]["parts"].present?
        body = message_info["payload"]["parts"][1]["body"]["data"]
      else
        body = message_info["payload"]["body"]["data"]
      end
      body = clean_body(body)
      body_en = translate(body)
      
      ## get analysis
      analysis = analysis(einstein_token, model_id, body_en)
      @analysises.push(analysis)

      ## if danger
      if analysis["probabilities"][0]["label"] == "danger"
        ## get danger_probability
      	danger_probability = analysis["probabilities"][0]["probability"]

        ## get receive_time and subject
        message_info["payload"]["headers"].count.times do |i|
          if message_info["payload"]["headers"][i]["name"] == "Date"
            @date = message_info["payload"]["headers"][i]["value"]
          end
          if message_info["payload"]["headers"][i]["name"] == "Subject"
            @subject = message_info["payload"]["headers"][i]["value"]
          end
        end

        ## get url
        url = "https://mail.google.com/mail/u/0/#all/#{message["id"]}"
        
        ## announce slack
        text = "★★★危険度#{danger_probability*100}%★★★\n【日時】#{@date}\n【件名】#{@subject}\n【本文】#{body}\n#{url}"
        slack_annnounce(text, current_user.slack_url)
        
        ## count danger
        i = i + 1
      end
    end
    if i == 0
      text = "危険なメールはなかったよ！セーフ！"
      slack_annnounce(text, current_user.slack_url)
    end
    redirect_to root_path, notice: "Slackへの通知が完了しました。"
  end
end
