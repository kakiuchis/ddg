class Message < ApplicationRecord
  belongs_to :user
  enum label: { safe: 0, danger: 1 }
end
