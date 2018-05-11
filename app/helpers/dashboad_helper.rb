module DashboadHelper
  def user_message_count(user)
    Message.where(user_id: user.id).count
  end

  def user_message_safe_count(user)
    Message.where(user_id: user.id, label: "safe").count
  end

  def user_message_danger_count(user)
    Message.where(user_id: user.id, label: "danger").count
  end

  def lesser_label_count(user)
  	[user_message_safe_count(user), user_message_danger_count(user)].min
  end

  def user_model_count(user)
  	Learn.where(user_id: user.id).count
  end
end
