class GmailCallbacksController < ApplicationController
  before_action :authenticate_user!
  include GmailCallbacksHelper
  include DetectHelper

  def redirect
    if params["after_date"] == ""
      redirect_to root_path, notice: "取得する過去日数を指定してください。" 
    else
      session[:after_date] = params["after_date"]

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
    after_date = session[:after_date]
    query = "from:#{current_user.boss_email} to:#{current_user.email} newer_than:#{after_date}d"
    max_i = 10

    messages = get_messages(token, query)["messages"]
    if messages == nil
      redirect_to root_path, notice: "設定したBOSSのメールアドレス、指定した過去日数ではメールがヒットしませんでした。" 
    else
      MessageUptakeJob.perform_later(token, messages, max_i, current_user)
      redirect_to root_path, notice: "現在メール取り込み中です。取り込み完了次第Slackで通知されます。" 
    end
  end
end
