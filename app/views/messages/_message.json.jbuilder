json.extract! message, :id, :message_id, :title, :body, :body_en, :label, :user_id, :created_at, :updated_at
json.url message_url(message, format: :json)
