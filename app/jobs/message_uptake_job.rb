class MessageUptakeJob < ApplicationJob
  include GmailCallbacksHelper
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
      # redirect_to controller: 'dashboad', action: 'index', notice: "#{i}件のメールを取り込みました。API無料枠の都合で1度に取得てきるメール数は#{max_i}件に制限されています。" unless i == 0
      # redirect_to controller: 'dashboad', action: 'index', notice: "設定したBOSSのメールアドレス、指定した過去日数のメールはすでに取り込まれています。" if i == 0
  end
end
