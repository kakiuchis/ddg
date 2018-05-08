class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message, only: [:edit, :update, :destroy, :safe_to_danger, :danger_to_safe]
  respond_to :js

  def index
    @messages = Message.user_choice_top_newer(current_user).all
  end

  def edit
  end

  def update
    if @message.update(message_params)
      redirect_to messages_path, notice: 'メッセージを変更しました。'
    else
      render :edit
    end
  end

  def destroy
    binding.pry
    # @message.destroy
    redirect_to messages_path, notice: 'メッセージを削除しました。'
  end

  def destroy_all
    binding.pry
    # Message.where(user_id: current_user.id).destroy_all
    redirect_to messages_path, notice: 'メッセージをすべて削除しました。'
  end

  def safe_to_danger
    @message.update(label: "danger")
    respond_with @message
  end

  def danger_to_safe
    @message.update(label: "safe")
    respond_with @message
  end

  private
    def set_message
      @message = Message.find(params[:id])
    end

    def message_params
      params.require(:message).permit(:id, :body_en)
    end
end
