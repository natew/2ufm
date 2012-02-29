Fusefm::Application.routes.draw do
  devise_for :users
  
  match "/users", :to => "users#index"
  match "/songs-new", :to => "songs#fresh"
  match "/activity", :to => "main#activity"
  
  resources :genres, :only => [:show]

  resources :blogs, :users
  
  resources :follows, :only => [:create, :destroy]
  resources :broadcasts, :only => [:create, :destroy]
  
  resources :listens, :only => [:create, :show]
  match "/l/:id", :to => "listens#show"
  
  resources :songs, :only => [:index, :show]
  
  match "/songs/:id", :to => "songs#failed", :as => :post
  
  resources :artists, :only => [:index, :show]

  match "/broadcasts/:song_id", :to => "broadcasts#create", :as => :post
  match "/follows/:station_id", :to => "follows#create", :as => :post

  root :to => 'main#index'
  
  # For Path.js home
  match "/home", :to => 'main#home'
  
  match "/search", :to => 'main#search'
  match "/loading", :to => 'main#loading'

end
