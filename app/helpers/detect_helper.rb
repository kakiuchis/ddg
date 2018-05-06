module DetectHelper
  def analysis(model_id, text)
  	uri = URI.parse("https://api.einstein.ai/v2/language/intent")
	request = Net::HTTP::Post.new(uri)
	request.content_type = "multipart/form-data"
	request["Authorization"] = "Bearer #{ENV['EINSTEIN_TOKEN']}"
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
end
