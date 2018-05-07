class Message < ApplicationRecord
  belongs_to :user
  enum label: { safe: 0, danger: 1 }

  def self.user_choice_top_newer(user)
    where(user_id: user.id).order(created_at: :desc)
  end

  def self.user_choice_lesser_count(user)
  	[where(user_id: user.id, label: "safe").count, where(user_id: user.id, label: "danger").count].min
  end

  def self.lesser_count_safe_data(user)
    where(user_id: user.id, label: "safe").order("RANDOM()").limit(self.user_choice_lesser_count(user))
  end

  def self.lesser_count_danger_data(user)
    where(user_id: user.id, label: "danger").order("RANDOM()").limit(self.user_choice_lesser_count(user))
  end
end
