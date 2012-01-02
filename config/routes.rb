CloudServersVpc::Application.routes.draw do

  resources :accounts
  resources :accounts do
    member do
      get 'limits'
    end
  end

  resources :auth
  resources :auth do
    collection do
      get 'index'
      post 'login'
      post 'logout'
    end
  end

  resources :clients

  resources :images
  resources :images do
    collection do
      post 'sync'
    end
  end

  resources :help

  resources :main

  resources :servers
  resources :servers do
    collection do
      post 'rebuild'
    end
  end

  resources :server_groups

  resources :server_errors

  resources :ssh_public_keys

  resources :users
  resources :users do
    collection do
      get 'password'
    end
  end

  root :to => "auth#index"

end
