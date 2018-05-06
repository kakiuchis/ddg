class Message < ApplicationRecord
  belongs_to :user
  enum label: { safe: 0, danger: 1 }

  def self.user_choice_top_newer(user)
    where(user_id: user.id).order(created_at: :desc)
  end
end
