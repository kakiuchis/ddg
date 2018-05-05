class LearnController < ApplicationController
  before_action :authenticate_user!
  include LearnHelper

  def new
  	filename = "case_routing_intent.csv"
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
    while training_status != "SUCCEEDED"
      sleep(60)
      @req_training_status = check_training_status(model_id)
      training_status = @req_training_status["status"]
    end

    text = "I'd like to buy some shoes"
    @result = test_model(model_id, text)
  end
end
