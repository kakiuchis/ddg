class DetectController < ApplicationController
  before_action :authenticate_user!
  include GmailCallbacksHelper
  include DetectHelper
  include LearnHelper

  def redirect
    session[:einstein_token] = params["einstein_token"]
    session[:newer_than_hour] = params["newer_than_hour"]
    if params["newer_than_hour"] == ""
      redirect_to root_path, notice: "取得する過去時間数を指定してください。" 
    elsif params["newer_than_hour"].to_i > 24
      redirect_to root_path, notice: "翻訳API無料枠の都合で検出できるメールは過去24時間までに制限されています。"
    elsif params["einstein_token"] == ""
      redirect_to root_path, notice: "Einstain Tokenを入力してください。"
    elsif check_token(params["einstein_token"]) == "invalid"
      redirect_to root_path, notice: "Einstain Tokenが正しくありません。"
    else
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
    google_token = session[:access_token]
    einstein_token = session[:einstein_token]
    newer_than_hour = session[:newer_than_hour]
    query = "from:#{current_user.boss_email} to:#{current_user.email} newer_than:#{newer_than_hour}h"
    model_id = Learn.user_choice_one_newer(current_user).modelId

    messages = get_messages(google_token, query)["messages"]
    if messages == nil
      redirect_to root_path, notice: "設定したBOSSのメールアドレス、指定した過去時間数ではメールがヒットしませんでした。" 
    else
      AnnounceJob.perform_later(messages, google_token, einstein_token, model_id, current_user, newer_than_hour)
      redirect_to root_path, notice: "Slackへの通知処理を行っています。"
    end
  end
end
