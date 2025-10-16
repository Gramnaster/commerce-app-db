Rails.application.routes.draw do
  # Take note of using "admin_users" instead of "users" at response body
  devise_for :admin_users, path: "api/v1/admin_users", path_names: {
    sign_in: "login",
    sign_out: "logout",
    registration: "signup"
  },
  controllers: {
    sessions: "api/v1/admin_users/sessions",
    registrations: "api/v1/admin_users/registrations"
  }

  devise_for :users, path: "api/v1/users", path_names: {
    sign_in: "login",
    sign_out: "logout",
    registration: "signup"
  },
  controllers: {
    sessions: "api/v1/users/sessions",
    registrations: "api/v1/users/registrations",
    confirmations: "api/v1/users/confirmations"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :users, only: [ :index, :show, :update, :destroy ]
      resources :admin_users, only: [ :index, :show, :update, :destroy ]
      resources :countries, only: [ :index, :show ]
      resources :products, only: [ :index, :show ]
      # resources :stocks, only: [ :index, :show ]
      # resources :countries, only: [ :index, :show ]
      # resources :wallets, only: [ :index, :show ] do
      #   get :my_wallet, on: :collection
      #   post :deposit, on: :collection
      #   post :withdraw, on: :collection
      # end
      # resources :historical_prices, only: [ :index, :show ]
      # resources :portfolios, only: [ :index, :show ] do
      #   get :my_portfolios, on: :collection
      #   post :buy, on: :collection
      #   post :sell, on: :collection
      # end
      # resources :receipts, only: [ :index, :show ] do
      #   get :my_receipts, on: :collection
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
  root "application#health_check"
end
