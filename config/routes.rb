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
      get "products/top_newest", to: "products#top_newest"
      resources :users, only: [ :index, :show, :update, :destroy ]
      resources :admin_users, only: [ :index, :show, :update, :destroy ]
      resources :countries, only: [ :index, :show ]
      resources :products, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          delete :delete_image
        end
      end
      resources :product_categories, only: [ :index, :show, :create, :update, :destroy ]
      resources :producers, only: [ :index, :show, :create, :update, :destroy ]
      resources :promotions, only: [ :index, :show, :create, :update, :destroy ]
      resources :promotions_categories, only: [ :index, :show, :create, :destroy ]
      resources :inventories, only: [ :index, :show, :create, :update, :destroy ]
      resources :company_sites, only: [ :index, :show ]

      # Shopping cart items (Users only - manage their own cart)
      resources :shopping_cart_items, only: [ :index, :show, :create, :update, :destroy ]

      # User payment methods (Users only - manage their own balance)
      get "user_payment_methods/balance", to: "user_payment_methods#balance"
      post "user_payment_methods/deposit", to: "user_payment_methods#deposit"
      post "user_payment_methods/withdraw", to: "user_payment_methods#withdraw"

      # User cart orders (Users create, Management views/approves)
      resources :user_cart_orders, only: [ :index, :show, :create, :update ] do
        member do
          patch :approve
        end
      end

      # Warehouse orders (Management creates, Management & Warehouse update)
      resources :warehouse_orders, only: [ :index, :show, :create, :update, :destroy ] do
        collection do
          get ":user_id/most_recent", to: "warehouse_orders#user_most_recent"
          get ":user_id/pending", to: "warehouse_orders#user_pending"
        end
      end

      # Receipts / Transaction History (Users only - view their own receipts)
      resources :receipts, only: [ :index, :show ]

      # Admin routes
      namespace :admin do
        # Admin receipts (Management only - view all, delete)
        resources :receipts, only: [ :index, :show, :destroy ]
      end

      resources :social_programs
      resources :social_program_receipts
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
