Fusefm::Application.routes.draw do
  #ActiveAdmin.routes(self)
  #devise_for :admin_users, ActiveAdmin::Devise.config
  devise_for :users
  
  match "/users", :to => "users#index"
  match "/songs/popular", :to => "songs#popular"
  match "/activity", :to => "main#activity"
  
  resources :genres, :only => [:show]

  resources :blogs, :posts, :songs, :stations, :favorites, :users, :artists

  root :to => 'main#index'
  
  # For Path.js home
  match "/home", :to => 'main#home'
  
  match "/search/:query", :to => 'main#search'
  match "/loading", :to => 'main#loading'

end
