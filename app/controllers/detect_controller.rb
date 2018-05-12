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
      redirect_to root_path, notice: "API無料枠の都合で検出できるメールは過去24時間までに制限されています。"
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
    @analysises = []
    i = 0
    
    ## get messages
    messages = get_messages(google_token, query)["messages"]
    if messages == nil
      redirect_to root_path, notice: "設定したBOSSのメールアドレス、指定した過去時間数ではメールがヒットしませんでした。" 
    else
      messages.reverse.each do |message|
        message_info = get_message_info(google_token, message["id"])

        # ## get body
        # if message_info["payload"]["parts"][0]["body"]["data"].present?
        #   body = message_info["payload"]["parts"][0]["body"]["data"]
        # elsif message_info["payload"]["parts"][1]["body"]["data"].present?
        #   body = message_info["payload"]["parts"][1]["body"]["data"]
        # else
        #   body = message_info["payload"]["body"]["data"]
        # end
        # body = clean_body(body)
        
        ## get snippet
        body = message_info["snippet"]
        if body.present?
          ## translate body
          body_en = translate(body) 

          # ## stop translate
          # body_en = body

          ## get analysis
          if check_token(einstein_token) == "valid"
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
              text = "★★★危険度#{BigDecimal((danger_probability*100).to_s).ceil(1).to_f}%★★★\n【日時】#{@date}\n【件名】#{@subject}\n【本文】#{body}\n#{url}"
              slack_annnounce(text, current_user.slack_url)
              
              ## count danger
              i = i + 1
            end
          end
        end
      end
      if i == 0
        text = "過去#{newer_than_hour}時間で#{messages.count}件のBOSSからのメールがありましたが、危険なメールはなかったよ！セーフ！\n以下証拠です\n#{@analysises}"
        slack_annnounce(text, current_user.slack_url)
      end
      if check_token(einstein_token) == "invalid"
        redirect_to root_path, notice: "Einstain Tokenの有効期限で正しく検出できていない可能性があります。再度発行し、検出しなおしましょう。"
      else
        redirect_to root_path, notice: "Slackへの通知が完了しました。"
      end
    end
  end
end
