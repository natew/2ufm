Fusefm::Application.routes.draw do
  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config

  devise_for :users

  resources :blogs, :posts, :songs, :stations, :favorites

  root :to => 'main#index'
  match "/search/:query", :to => 'main#search'
 
  match "/users", :to => "users#index"

end
