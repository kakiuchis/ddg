Rails.application.routes.draw do
  resources :messages
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  root 'top#index'
  get '/gmail_callbacks/uptake', to: 'gmail_callbacks#uptake'
  get '/gmail_callbacks/callback', to: 'gmail_callbacks#callback'
  get '/gmail_callbacks/redirect', to: 'gmail_callbacks#redirect'
end
