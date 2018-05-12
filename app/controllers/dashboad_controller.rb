class DashboadController < ApplicationController
  include DetectHelper
  def index
  end

  def test
  	if user_signed_in?
  	  slack_annnounce("テスト成功です！ようこそDDGへ！！", current_user.slack_url)
  	  redirect_to root_path, notice: "Slackの通知を確認してください。"
  	else
　　　　　redirect_to root_path, notice: "ログインしてください。"
    end
  end
end
