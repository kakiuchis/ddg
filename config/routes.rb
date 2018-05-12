Rails.application.routes.draw do

  
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  root 'dashboad#index'
  get '/dashboad/test'

  post '/gmail_callbacks/redirect'
  get '/gmail_callbacks/callback'
  get '/gmail_callbacks/uptake'

  resources :messages, only: [:index, :edit, :update, :destroy]
  post '/messages/safe_to_danger'
  post '/messages/danger_to_safe'
  delete :messages, to: 'messages#destroy_all'
  
  get '/learn/index'
  post '/learn/new'
  resources :learn, only: [:destroy]
  delete :learn, to: 'learn#destroy_all'

  post '/detect/redirect'
  get '/detect/callback'
  get '/detect/uptake'
end
