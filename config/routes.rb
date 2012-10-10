Fusefm::Application.routes.draw do
  mount RailsAdmin::Engine => '/admin', :as => 'rails_admin'
  mount MailsViewer::Engine => '/delivered_mails' if Rails.env.development?

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

  match "/tune/:id", :to => "users#tune"
  match "/live/:id", :to => "users#live"
  match "/play/:id", :to => "songs#play"
  match "/l/:id", :to => "listens#show"
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
  match '/unsubscribe/:type/:key', to: 'users#unsubscribe'

  ### BELOW HERE MATCH /:STATION_SLUG ROUTES ###

  # Root level stations access
  match "/:id", :to => 'stations#show', :as => :station
  match "/:id", :to => 'stations#show', :as => :artist
  match "/:id", :to => 'stations#show', :as => :blog
  match "/:id", :to => 'stations#show', :as => :user

  # Users
  match '/:id/following', :to => 'users#following', :as => 'user_following'
  match '/:id/followers', :to => 'users#followers', :as => 'user_followers'

  resources :users, path: '/' do
    member do
      get 'following'
      get 'followers'
      get 'feed'
    end
  end

  # Artists
  resources :artists, path: '/' do
    member do
      get 'remixes_of'
      get 'remixes_by'
      get 'originals'
      get 'popular'
      get 'mashups'
      get 'covers'
      get 'features'
      get 'productions'
    end
  end
end
