Fusefm::Application.routes.draw do
  # Redirects
  match "/stations/:id", :to => redirect("/%{id}")

  devise_for :users, :controllers => {
    :registrations => 'registrations',
    :sessions => 'sessions'
  }

  match "/users", :to => "users#index"
  match "/songs-new", :to => "songs#fresh"
  match "/activity", :to => "main#activity"

  resources :genres, :only => [:show]
  resources :blogs
  resources :users
  resources :stations, :only => [:show, :index]
  resources :follows, :only => [:create, :destroy]
  resources :broadcasts, :only => [:create, :destroy]
  resources :comments, :only => [:create, :destroy]

  resources :listens, :only => [:create, :show]
  match "/l/:id", :to => "listens#show"

  resources :songs, :only => [:index, :show]

  match "/songs/:id", :to => "songs#failed", :as => :post

  resources :artists, :only => [:index, :show] do
    member do
      get 'remixes'
      get 'originals'
      get 'popular'
      get 'mashups'
      get 'covers'
      get 'productions'
      get 'features'
    end
  end

  match "/broadcasts/:song_id", :to => "broadcasts#create", :as => :post
  match "/follows/:station_id", :to => "follows#create", :as => :post

  root :to => 'main#index'

  match "/search", :to => 'main#search'
  match "/loading", :to => 'main#loading'

  match '/mac', :to => 'main#mac'

  # Root level stations access
  match "/:id", :to => 'stations#show'
end
