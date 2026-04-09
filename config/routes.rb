# frozen_string_literal: true

Rails.application.routes.draw do
  root 'pages#dashboard'

  namespace :api, defaults: { format: :json } do
    resources :landlords, only: %i[index show]
    resources :leases, only: %i[index show]
    resources :properties, only: %i[index]
    resources :invoices, only: %i[index]
    get 'stats', to: 'stats#index'
  end
end
