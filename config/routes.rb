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

  match "/p-:p", :to => "songs#trending"
  match "/songs/fresh(/p-:p)", :to => "songs#fresh", :as => 'songs_fresh'
  match "/songs/popular(/p-:p)", :to => "songs#popular", :as => 'songs_popular'
  match "/genres/:id(/p-:p)", :to => "genres#show"

  resources :songs, only: [:index, :show]
  resources :follows, only: [:create, :destroy]
  resources :broadcasts, only: [:create, :destroy]
  resources :comments, only: [:create, :destroy]
  resources :comments, only: [:create]
  resources :listens, only: [:create, :show]
  resources :actions, only: [:create]
  resources :genres, only: [:index, :show]
  resources :blogs, only: [:new]

  match '/browse/artists(/:letter)', to: 'artists#index', as: 'artists'
  match '/browse/users(/:letter)', to: 'users#index', as: 'users'
  match '/browse(/:genre)', to: 'blogs#index', as: 'blogs'

  resources :shares, :only => [:create]
  match '/shares/inbox', :to => 'shares#inbox'
  match '/shares/outbox', :to => 'shares#outbox'

  match "/tune/:id", :to => "users#tune"
  match "/live/:id", :to => "users#live"
  match "/@:id", :to => "users#live"
  match "/play/:id", :to => "songs#play"
  match "/l/:id", :to => "listens#show"
  match "/songs/:id", :to => "songs#failed", :as => :post
  match "/broadcasts/:song_id", :to => "broadcasts#create", :as => :post
  match "/follows/:station_id", :to => "follows#create", :as => :post
  match "/search", :to => 'main#search'
  match "/loading", :to => 'main#loading'
  match '/dl/mac', :to => 'main#mac'
  match '/my/account', :to => 'users#edit', :as => 'user_account'
  match '/my/privacy', :to => 'users#privacy', :as => 'user_privacy'
  match '/activate/:id/:key', :to => 'users#activate'
  match "/navbar", :to => 'users#navbar'
  match '/share', :to => 'shares#create'
  match '/unsubscribe/:type/:key', to: 'users#unsubscribe'
  match '/my/genres', to: 'users#genres'
  match '/my/friends', to: 'users#find_friends', :as => 'users_friends'
  match '/do/authorized', to: 'users#authorized'

  ### BELOW HERE MATCH /:STATION_SLUG ROUTES ###

  # Root level stations access
  match "/:id(/p-:p)", :to => 'stations#show', :as => :station
  match "/:id", :to => 'stations#show', :as => :artist
  match "/:id", :to => 'stations#show', :as => :blog
  match "/:id", :to => 'stations#show', :as => :user

  resources :main, only:[], path: '/us' do
    member do
      get 'about'
      get 'legal'
      get 'privacy'
      get 'contact'
    end
  end

  match '/:id/feed/p-:p', to: 'users#feed'

  resources :users, only:[], path: '/' do
    member do
      get 'following'
      get 'followers'
      get 'feed'
    end
  end

  resources :blogs, only:[:new], path: '/' do
    member do
      get 'popular'
    end
  end

  # Artists
  resources :artists, only:[], path: '/' do
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
