class LearnController < ApplicationController
  before_action :authenticate_user!
  include LearnHelper
  def index
    @learns = Learn.all
  end

  def new
    token = params["einstein_token"]

    ## output csv
    filename = current_user.email.gsub(/@.*/, "") + DateTime.now.to_i.to_s + ".csv"
    require 'csv'
    CSV.open("app/data/#{filename}", "w", force_quotes: true) do |row|
      Message.lesser_count_safe_data(current_user).each do |message|
        row << [ message.body_en, message.label ]
      end
      Message.lesser_count_danger_data(current_user).each do |message|
        row << [ message.body_en, message.label ]
      end
    end
    
    ## datasets upload
    req_datasets_upload = datasets_upload(token, filename)
    dataset_id = req_datasets_upload["id"]
    sleep(30)
    
    ## dataset upload status check
    req_dataset_upload_status = check_upload_status(token, dataset_id)
    dataset_statusMsg = req_dataset_upload_status["statusMsg"]
    while dataset_statusMsg != "SUCCEEDED"
      sleep(10)
      req_dataset_upload_status = check_upload_status(token, dataset_id)
      dataset_statusMsg = req_dataset_upload_status["statusMsg"]
    end

    ## training
    req_training = training(token, dataset_id)
    model_id = req_training["modelId"]
    sleep(30)

    ## trainig status check
    @req_training_status = check_training_status(token, model_id)
    training_status = @req_training_status["status"]
    while training_status != "SUCCEEDED"
      sleep(30)
      @req_training_status = check_training_status(token, model_id)
      training_status = @req_training_status["status"]
    end

    ## record learning
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

    # ## test model
    # text = "I'd like to buy some shoes"
    # @result = test_model(token, model_id, text)
  end
end
