Fusefm::Application.routes.draw do
  # Redirects
  match "/stations/:id", :to => redirect("/%{id}")

  devise_for :users, :controllers => {
    :registrations => 'registrations',
    :sessions => 'sessions'
  }

  match "/songs-new", :to => "songs#fresh"

  resources :genres, :only => [:show]
  resources :blogs, :except => [:show]
  resources :users, :except => [:show]
  resources :follows, :only => [:create, :destroy]
  resources :broadcasts, :only => [:create, :destroy]
  resources :comments, :only => [:create, :destroy]
  resources :artists, :only => [:index]
  resources :stations, :only => [:index]
  resources :comments, :only => [:create]

  resources :listens, :only => [:create, :show]
  match "/l/:id", :to => "listens#show"

  resources :songs, :only => [:index, :show]

  match "/songs/:id", :to => "songs#failed", :as => :post

  match "/broadcasts/:song_id", :to => "broadcasts#create", :as => :post
  match "/follows/:station_id", :to => "follows#create", :as => :post

  match "/search", :to => 'main#search'
  match "/loading", :to => 'main#loading'

  match '/mac', :to => 'main#mac'

  ### BELOW HERE MATCH /:STATION_SLUG ROUTES ###

  # Artists
  match "/:id/remixes", :to => "artists#remixes", :as => "artist_remixes"
  match "/:id/originals", :to => "artists#originals", :as => "artist_originals"
  match "/:id/popular", :to => "artists#popular", :as => "artist_popular"
  match "/:id/mashups", :to => "artists#mashups", :as => "artist_mashups"
  match "/:id/covers", :to => "artists#covers", :as => "artist_covers"
  match "/:id/productions", :to => "artists#productions", :as => "artist_productions"
  match "/:id/features", :to => "artists#features", :as => "artist_features"

  # Root level stations access
  match "/:id", :to => 'stations#show', :as => "station"
  match "/:id", :to => 'stations#show', :as => "artist"
  match "/:id", :to => 'stations#show', :as => "blog"
  match "/:id", :to => 'stations#show', :as => "user"

  root :to => 'main#index'
end
