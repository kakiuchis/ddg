module DetectHelper
  def analysis(token, model_id, text)
  	uri = URI.parse("https://api.einstein.ai/v2/language/intent")
	request = Net::HTTP::Post.new(uri)
	request.content_type = "multipart/form-data"
	request["Authorization"] = "Bearer #{token}"
	request["Cache-Control"] = "no-cache"
    data = [
      ["modelId", model_id],
      ["document", text],
    ]
    request.set_form(data, "multipart/form-data")
	req_options = { use_ssl: uri.scheme == "https"}
	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
	  http.request(request)
	end
	JSON.parse(response.body)
  end

  def slack_annnounce(hash, webhook_url)
  	uri = URI.parse(webhook_url)
	request = Net::HTTP::Post.new(uri)
	request.content_type = "application/json"
	request.body = JSON.dump({
	  "text": "#{text}"
	})

	req_options = {
	  use_ssl: uri.scheme == "https",
	}

	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
	  http.request(request)
	end
  end
end
