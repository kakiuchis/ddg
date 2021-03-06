module GmailCallbacksHelper
  def get_messages(token, query)
    uri = URI.parse("https://www.googleapis.com/gmail/v1/users/me/messages?q=#{query}")
  	request = Net::HTTP::Get.new(uri)
  	request["Authorization"] = "Bearer #{token}"
  	req_options = { use_ssl: uri.scheme == "https" }
  	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  	  http.request(request)
  	end
  	JSON.parse(response.body)
  end

  def get_message_info(token, id)
    uri = URI.parse("https://www.googleapis.com/gmail/v1/users/me/messages/#{id}")
  	request = Net::HTTP::Get.new(uri)
  	request["Authorization"] = "Bearer #{token}"
  	req_options = { use_ssl: uri.scheme == "https" }
  	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  	  http.request(request)
  	end
  	JSON.parse(response.body)
  end

  # def clean_body(body)
  #   body = Base64.urlsafe_decode64(body)
  #   body = body.gsub(/\r\n|\r|\n/, " ")
  #   body = body.gsub(/<div dir=\"auto\">|<br>/, " ")
  #   body = body.gsub(/<div data-smartmail=\"gmail_signature\" dir=\"auto\">.*/, " ")
  #   body = body.gsub(/<div data-smartmail=\"gmail_signature\">.*/, " ")
  #   body = body.gsub(/<div class=\"gmail_signature\">.*/, " ")
  #   body = body.gsub(/<div class=\"gmail_signature\" data-smartmail=\"gmail_signature\">.*/, " ")
  #   body = body.gsub(/<div class=\"m_\d+gmail_signature\" data-smartmail=\"gmail_signature\">.*/, " ")
  #   body = ActionController::Base.helpers.strip_tags(body).strip
  #   body = " " if body.blank?
  #   body
  # end

  def translate(text)
    uri = URI.parse("https://gateway.watsonplatform.net/language-translator/api/v2/translate")
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(ENV['WATSON_TRANSLATE_USERNAME'], ENV['WATSON_TRANSLATE_PASSWORD'])
    request["Accept"] = "application/json"
    request.body = JSON.dump({
      "text": text,
      "source": "ja",
      "target": "en"
    })
    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  	JSON.parse(response.body)["translations"][0]["translation"]
  end
end
