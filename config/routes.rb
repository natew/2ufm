Fusefm::Application.routes.draw do
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'

  if Rails.env.development?
    mount MailsViewer::Engine => '/delivered_mails'
  end

  root :to => 'songs#trending'

  # Redirects
  match "/stations/:id", :to => redirect("/%{id}")

  devise_for :users, :controllers => {
    :registrations => 'registrations',
    :sessions => 'sessions',
    :omniauth_callbacks => 'users/omniauth_callbacks'
  }

  devise_scope :user do
    resources :sessions, :only => [:new]
    match '/login', :to => 'users#new'
  end

  match 'confirm/:confirmation_token', :to => 'confirmations#show', :as => 'user_confirm'

  resources :songs, :only => [:index, :show]
  resources :genres, :only => [:show]
  resources :blogs, :except => [:show]
  resources :users, :except => [:show]
  resources :follows, :only => [:create, :destroy]
  resources :broadcasts, :only => [:create, :destroy]
  resources :comments, :only => [:create, :destroy]
  resources :artists, :only => [:index]
  resources :comments, :only => [:create]
  resources :listens, :only => [:create, :show]

  resources :shares, :only => [:create]
  match '/shares/inbox', :to => 'shares#inbox'
  match '/shares/outbox', :to => 'shares#outbox'

  match "/play/:id", :to => "songs#play"
  match "/l/:id", :to => "listens#show"
  match "/feed", :to => "users#feed", :as => 'user_root'
  match "/fresh", :to => "songs#fresh"
  match "/popular", :to => "songs#popular"
  match "/songs/:id", :to => "songs#failed", :as => :post
  match "/broadcasts/:song_id", :to => "broadcasts#create", :as => :post
  match "/follows/:station_id", :to => "follows#create", :as => :post
  match "/search", :to => 'main#search'
  match "/loading", :to => 'main#loading'
  match '/mac', :to => 'main#mac'
  match '/account', :to => 'users#edit'
  match '/activate/:id/:key', :to => 'users#activate'
  match "/navbar", :to => 'users#navbar'
  match '/share', :to => 'shares#create'
  match '/authorized', :to => 'users#authorized'

  ### BELOW HERE MATCH /:STATION_SLUG ROUTES ###

  # Artists
  match "/:id/remixes", :to => "artists#remixes", :as => "artist_remixes"
  match "/:id/originals", :to => "artists#originals", :as => "artist_originals"
  match "/:id/popular", :to => "artists#popular", :as => "artist_popular"
  match "/:id/mashups", :to => "artists#mashups", :as => "artist_mashups"
  match "/:id/covers", :to => "artists#covers", :as => "artist_covers"
  match "/:id/productions", :to => "artists#productions", :as => "artist_productions"
  match "/:id/features", :to => "artists#features", :as => "artist_features"

  # Users
  match '/:id/following', :to => 'users#following', :as => 'user_following'
  match '/:id/followers', :to => 'users#followers', :as => 'user_followers'

  # Root level stations access
  match "/:id", :to => 'stations#show', :as => :station
  match "/:id", :to => 'stations#show', :as => :artist
  match "/:id", :to => 'stations#show', :as => :blog
  match "/:id", :to => 'stations#show', :as => :user
end
