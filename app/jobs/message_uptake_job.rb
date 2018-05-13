class MessageUptakeJob < ApplicationJob
  include GmailCallbacksHelper
  include DetectHelper
  queue_as :default
  
  def perform(token, messages, max_i, current_user)
	  uptake_time = Time.now
    i = 0
    messages.reverse.each do |message|
      ## remove overlap
      unless Message.pluck(:message_id).include?(message["id"])
        message_info = get_message_info(token, message["id"])

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
        
        # ## translate body
        # body_en = "" if body.blank?
        # body_en = translate(body) if body.present?

        ## stop translate
        body_en = body
        
        ## get receive_time and subject
        message_info["payload"]["headers"].count.times do |i|
          if message_info["payload"]["headers"][i]["name"] == "Date"
            @date = message_info["payload"]["headers"][i]["value"]
          end
          if message_info["payload"]["headers"][i]["name"] == "Subject"
            @subject = message_info["payload"]["headers"][i]["value"]
          end
        end
        
        if body.present?
          ## save message
          Message.create(
            message_id: message["id"],
            user_id: current_user.id,
            date: @date,
            title:  @subject,
            body:  body,
            body_en: body_en,
            uptake_time: uptake_time,
          )

          ## count save
          i = i + 1
        end

        ## wotson api restriction
        break if i == max_i
      end
    end
    if i == 0
      text = "指定した時間のBOSSからのメールは既に取り込まれています。\nhttps://ddgfb.herokuapp.com/"
      slack_annnounce(text, current_user.slack_url)
    elsif i > 0 && i < max_i
      text = "BOSSからのメールが#{i}件取り込まれました。\nhttps://ddgfb.herokuapp.com/"
      slack_annnounce(text, current_user.slack_url)  
    else
      text = "BOSSからのメールが#{i}件取り込まれました。\n翻訳API無料枠の都合で1度に取得できるメールは最大#{max_i}に制限しています。\nhttps://ddgfb.herokuapp.com/"
      slack_annnounce(text, current_user.slack_url) 
    end
  end
end
