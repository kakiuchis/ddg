class Message < ApplicationRecord
  belongs_to :user
  enum label: { safe: 0, danger: 1 }

  def self.user_choice(user)
    where(user_id: user.id)
  end
end
