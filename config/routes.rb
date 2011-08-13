Fusefm::Application.routes.draw do
  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config

  devise_for :users

  resources :blogs, :posts, :songs, :stations

  root :to => 'main#index'

end
