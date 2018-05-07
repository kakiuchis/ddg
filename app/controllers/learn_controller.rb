class LearnController < ApplicationController
  before_action :authenticate_user!
  include LearnHelper

  def index
    @learns = Learn.all
  end

  def new
    # filename = current_user.email.gsub(/@.*/, "") + DateTime.now.to_i.to_s + ".csv"
    filename = "case_routing_intent.csv"
    require 'csv'
    # CSV.open("app/data/#{filename}", "w") do |row|
    #   Message.user_choice_top_newer(current_user).all.each do |message|
    #     message.body_en = '"' + message.body_en + '"'
    #     row << [ "\'#{message.body_en}\'", message.label ]
    #   end
    # end

    req_datasets_upload = datasets_upload(filename)
    dataset_id = req_datasets_upload["id"]
    sleep(30)
    

    req_dataset_upload_status = check_upload_status(dataset_id)
    dataset_statusMsg = req_dataset_upload_status["statusMsg"]
    while dataset_statusMsg != "SUCCEEDED"
      sleep(10)
      req_dataset_upload_status = check_upload_status(dataset_id)
      dataset_statusMsg = req_dataset_upload_status["statusMsg"]
    end

    req_training = training(dataset_id)
    model_id = req_training["modelId"]
    sleep(330)

    @req_training_status = check_training_status(model_id)
    training_status = @req_training_status["status"]
    binding.pry
    while training_status != "SUCCEEDED"
      sleep(60)
      @req_training_status = check_training_status(model_id)
      training_status = @req_training_status["status"]
    end

    Learn.create(
      fileName: filename,
      datasetId: @req_training_status["datasetId"],
      modelId:  @req_training_status["modelId"],
      lavels:  @req_training_status["trainStats"]["labels"],
      examples: @req_training_status["trainStats"]["examples"],
      testSplitSize: @req_training_status["trainStats"]["testSplitSize"],
      trainSplitSize: @req_training_status["trainStats"]["trainSplitSize"],
      trainingTime: @req_training_status["trainStats"]["trainingTime"],
      lastEpochDone: @req_training_status["trainStats"]["lastEpochDone"],
      datasetLoadTime: @req_training_status["trainStats"]["datasetLoadTime"],
      user_id: current_user.id,
    )

    text = "I'd like to buy some shoes"
    binding.pry
    @result = test_model(model_id, text)
  end
end
