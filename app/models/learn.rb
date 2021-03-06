class Learn < ApplicationRecord
  belongs_to :user

  def self.user_choice_one_newer(user)
    where(user_id: user.id).order(created_at: :desc).limit(1)[0]
  end

  def self.user_choice(user)
    where(user_id: user.id)
  end
end
