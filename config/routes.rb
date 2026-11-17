Rails.application.routes.draw do
  resources :audit_logs, only: [:index]

  # 关键：new_dispatch 用 collection 的 get，dispatch/pause/resume 用 post
  resources :transfers, only: [:index, :show] do
    collection do
      get  :new_dispatch
      post :submit_dispatch
      post :pause
      post :resume
    end
  end

  resources :tokens, only: [:index, :create, :destroy]
  resources :to_addresses do
      collection do
        get  :import
        post :do_import
        post :refresh_balances
        post :backup_keystore
      end
      member { get :qr }
    end
  resources :from_addresses do
     collection do
       get  :import
       post :do_import
       post :refresh_balances
       post :backup_keystore
     end
     member { get :qr }
   end
  # devise_for :users
  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords",
    confirmations: "users/confirmations",
    unlocks: "users/unlocks"
  }
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#welcome"
end
