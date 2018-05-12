class GmailCallbacksController < ApplicationController
  before_action :authenticate_user!
  include GmailCallbacksHelper

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
    max_i = 5

    ## get messages
    messages = get_messages(token, query)["messages"]
    if messages == nil
      redirect_to root_path, notice: "設定したBOSSのメールアドレス、指定した過去日数ではメールがヒットしませんでした。" 
    else
      MessageUptakeJob.perform_later(token, messages, max_i, current_user)
      # i = 0
      # max_i = 45
      # messages.reverse.each do |message|
      #   ## remove overlap
      #   unless Message.pluck(:message_id).include?(message["id"])
      #     message_info = get_message_info(token, message["id"])

      #     # ## get body
      #     # if message_info["payload"]["parts"][0]["body"]["data"].present?
      #     #   body = message_info["payload"]["parts"][0]["body"]["data"]
      #     # elsif message_info["payload"]["parts"][1]["body"]["data"].present?
      #     #   body = message_info["payload"]["parts"][1]["body"]["data"]
      #     # else
      #     #   body = message_info["payload"]["body"]["data"]
      #     # end
      #     # body = clean_body(body)
          
      #     ## get snippet
      #     body = message_info["snippet"]
          
      #     ## translate body
      #     body_en = "" if body.blank?
      #     body_en = translate(body) if body.present?

      #     # ## stop translate
      #     # body_en = body
          
      #     ## get receive_time and subject
      #     message_info["payload"]["headers"].count.times do |i|
      #       if message_info["payload"]["headers"][i]["name"] == "Date"
      #         @date = message_info["payload"]["headers"][i]["value"]
      #       end
      #       if message_info["payload"]["headers"][i]["name"] == "Subject"
      #         @subject = message_info["payload"]["headers"][i]["value"]
      #       end
      #     end
          
      #     if body.present?
      #       ## save message
      #       Message.create(
      #         message_id: message["id"],
      #         user_id: current_user.id,
      #         date: @date,
      #         title:  @subject,
      #         body:  body,
      #         body_en: body_en,
      #         uptake_time: uptake_time,
      #       )

      #       ## count save
      #       i = i + 1
      #     end

      #     ## wotson api restriction
      #     break if i == max_i
      #   end
      # end
      # redirect_to root_path, notice: "#{i}件のメールを取り込みました。API無料枠の都合で1度に取得てきるメール数は#{max_i}件に制限されています。" unless i == 0
      # redirect_to root_path, notice: "設定したBOSSのメールアドレス、指定した過去日数のメールはすでに取り込まれています。" if i == 0
      redirect_to root_path, notice: "現在メール取り込み中ですので、しばらくしたら更新してください。API無料枠の都合で1度に取得てきるメール数は#{max_i}件に制限されています。同一メールは取り込まれません。" 
    end
  end
end
