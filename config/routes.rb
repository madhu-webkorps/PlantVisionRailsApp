require "sidekiq/web"

Rails.application.routes.draw do
  root "seed_analyses#index"
  resources :seed_analyses do
    member do
    end
  end

  if Rails.env.development?
    mount Sidekiq::Web => "/sidekiq"
  end
end
