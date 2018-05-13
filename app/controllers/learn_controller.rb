class LearnController < ApplicationController
  before_action :authenticate_user!
  include LearnHelper
  def index
    @learns = Learn.user_choice(current_user).reverse
  end

  def new
    token = params["einstein_token"]
    if token == ""
      redirect_to root_path, notice: "Einstain Tokenを入力してください。"
    elsif check_token(token) == "invalid"
      redirect_to root_path, notice: "Einstain Tokenが正しくありません。"
    else
      LearningJob.perform_later(current_user, token)
      redirect_to root_path, notice: "ただいま学習中です。今しばらくお待ちください。"
    end
  end

  def destroy
    if Learn.find(params[:id]).user_id != current_user.id
      redirect_to learn_index_path
    else
      Learn.find(params[:id]).destroy
      redirect_to learn_index_path, notice: "学習データを削除しました。"
    end
  end

  def destroy_all
    Learn.where(user_id: current_user.id).destroy_all
    redirect_to learn_index_path, notice: "学習データをすべて削除しました。"
  end
end
