module LearnHelper
  def datasets_upload(token, filename)
  	uri = URI.parse("https://api.einstein.ai/v2/language/datasets/upload")
	request = Net::HTTP::Post.new(uri)
	request.content_type = "multipart/form-data"
	request["Authorization"] = "Bearer #{token}"
	request["Cache-Control"] = "no-cache"
	req_options = { use_ssl: uri.scheme == "https"}
	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
	  File.open("app/data/#{filename}") do |file|
        data = [
          ["type", "text-intent"],
          ["data", file],
        ]
        request.set_form(data, "multipart/form-data")
        http.request(request)
      end
	end
	JSON.parse(response.body)
  end

  def check_upload_status(token, dataset_id)
  	uri = URI.parse("https://api.einstein.ai/v2/language/datasets/#{dataset_id}")
	request = Net::HTTP::Get.new(uri)
	request["Authorization"] = "Bearer #{token}"
	request["Cache-Control"] = "no-cache"
	req_options = { use_ssl: uri.scheme == "https"}
	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
	  http.request(request)
	end
	JSON.parse(response.body)
  end

  def check_token(token)
  	if check_upload_status(token, 1055400)["message"] == "Invalid access token"
  	  p "invalid"
  	elsif check_upload_status(token, 1055400)["message"] == "Invalid authentication scheme"
  	  p "invalid"
  	else
  	  p "valid"
  	end
  end

  def training(token, dataset_id)
	uri = URI.parse("https://api.einstein.ai/v2/language/train")
	request = Net::HTTP::Post.new(uri)
	request.content_type = "multipart/form-data"
	request["Authorization"] = "Bearer #{token}"
	request["Cache-Control"] = "no-cache"
	data = [
      ["name", "Service Request Routing Model"],
      ["datasetId", dataset_id.to_s],
    ]
    request.set_form(data, "multipart/form-data")
	req_options = { use_ssl: uri.scheme == "https"}
	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
	  http.request(request)
	end
	JSON.parse(response.body)
  end

  def check_training_status(token, model_id)
  	uri = URI.parse("https://api.einstein.ai/v2/language/train/#{model_id}")
	request = Net::HTTP::Get.new(uri)
	request["Authorization"] = "Bearer #{token}"
	request["Cache-Control"] = "no-cache"
    req_options = { use_ssl: uri.scheme == "https"}
	response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
	  http.request(request)
	end
	JSON.parse(response.body)
  end

  def test_model(token, model_id, text)
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
end
