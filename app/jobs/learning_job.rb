class LearningJob < ApplicationJob
  include LearnHelper
  include DetectHelper
  queue_as :default

  def perform(current_user, token)
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
    if check_token(token) == "valid"
      req_datasets_upload = datasets_upload(token, filename)
      dataset_id = req_datasets_upload["id"]
      sleep(10)
    end
    
    ## dataset upload status check
    if check_token(token) == "valid" && dataset_id.present?
      req_dataset_upload_status = check_upload_status(token, dataset_id)
      dataset_statusMsg = req_dataset_upload_status["statusMsg"]
      while dataset_statusMsg == "UPLOADING"
        sleep(10)
        if check_token(token) == "valid"
          req_dataset_upload_status = check_upload_status(token, dataset_id)
          dataset_statusMsg = req_dataset_upload_status["statusMsg"]
        end
      end
    end

    ## training
    if check_token(token) == "valid" && dataset_statusMsg == "SUCCEEDED"
      req_training = training(token, dataset_id)
      model_id = req_training["modelId"]
      sleep(300)
    end

    ## trainig status check
    if check_token(token) == "valid" && model_id.present?
      @req_training_status = check_training_status(token, model_id)
      training_status = @req_training_status["status"]
      while training_status == "RUNNING" || training_status == "QUEUED"
        sleep(60)
        if check_token(token) == "valid"
          @req_training_status = check_training_status(token, model_id)
          training_status = @req_training_status["status"]
        end
      end
    end

    ## record learning
    if check_token(token) == "valid" && training_status == "SUCCEEDED"
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
    end

    if check_token(token) == "valid" && training_status == "SUCCEEDED"
      text = "学習が完了しました。\nhttps://ddgfb.herokuapp.com/"
      slack_annnounce(text, current_user.slack_url)
    elsif check_token(token) == "invalid"
      text = "学習中にEinstein Tokenが失効しました。再発行し再度学習してください。\nhttps://ddgfb.herokuapp.com/"
      slack_annnounce(text, current_user.slack_url)
    else
      text = "学習が失敗しました。管理者に報告してください。\nkakiuchis@gmail.com\nhttps://ddgfb.herokuapp.com/"
      slack_annnounce(text, current_user.slack_url)
    end
  end
end
