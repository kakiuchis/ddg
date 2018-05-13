class AnnounceJob < ApplicationJob
  include GmailCallbacksHelper
  include DetectHelper
  include LearnHelper
  queue_as :default

  def perform(messages, google_token, einstein_token, model_id, current_user, newer_than_hour)
	  @analysises = []
    i = 0
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
        if check_token(einstein_token) == "invalid"
          i = "invalid"
          break
        else
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
            text = "★★★危険度#{BigDecimal((danger_probability*100).to_s).ceil(1).to_f}%★★★\n【日時】#{@date}\n【件名】#{@subject}\n【本文】#{body}\n【Gmailリンク】#{url}"
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
    elsif i == "invalid"
      text = "検出中にEinstein Tokenが失効しました。再発行しもう一度検出してください。\nhttps://ddgfb.herokuapp.com/"
      slack_annnounce(text, current_user.slack_url) 
    else
      text = "以上、過去#{newer_than_hour}時間で#{messages.count}件のBOSSからのメールがありましたが、#{i}件のdangerなメールが検出されました。\nhttps://ddgfb.herokuapp.com/"
      slack_annnounce(text, current_user.slack_url) 
    end
  end
end
