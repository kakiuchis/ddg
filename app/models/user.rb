class User < ApplicationRecord
  has_many :message, dependent: :destroy
  has_many :learn, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  def self.find_for_google_oauth(auth)
    user = User.find_by(email: auth.info.email)

    unless user
      user = User.create(
          provider: auth.provider,
          uid:      auth.uid,
          email: auth.info.email,
          token: auth.credentials.token,
          password: Devise.friendly_token[0, 20]
      )
    end
    user
  end
end
