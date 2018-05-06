Rails.application.routes.draw do

  resources :messages
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  root 'dashboad#index'

  get '/gmail_callbacks/redirect'
  get '/gmail_callbacks/callback'
  get '/gmail_callbacks/uptake'
  
  get '/learn/new', to: 'learn#new'
  
  post '/messages/safe_to_danger'
  post '/messages/danger_to_safe'

  get '/detect/redirect'
  get '/detect/callback'
  get '/detect/uptake'
end
