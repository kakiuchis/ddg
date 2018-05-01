Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  root 'top#index'
  get '/gmail_callbacks/messages', to: 'gmail_callbacks#messages'
  get '/gmail_callbacks/callback', to: 'gmail_callbacks#callback'
  get '/gmail_callbacks/redirect', to: 'gmail_callbacks#redirect'
end
