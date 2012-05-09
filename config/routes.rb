Fusefm::Application.routes.draw do
  devise_for :users, :controllers => {
    :registrations => 'registrations',
    :sessions => 'sessions'
  }

  match "/users", :to => "users#index"
  match "/songs-new", :to => "songs#fresh"
  match "/activity", :to => "main#activity"

  resources :genres, :only => [:show]

  resources :blogs,
            :users,
            :stations

  resources :follows, :only => [:create, :destroy]
  resources :broadcasts, :only => [:create, :destroy]

  resources :listens, :only => [:create, :show]
  match "/l/:id", :to => "listens#show"

  resources :songs, :only => [:index, :show]

  match "/songs/:id", :to => "songs#failed", :as => :post

  resources :artists, :only => [:index, :show] do
    member do
      get 'remixes_of'
      get 'remixes_by'
      get 'originals'
      get 'popular'
    end
  end

  match "/broadcasts/:song_id", :to => "broadcasts#create", :as => :post
  match "/follows/:station_id", :to => "follows#create", :as => :post

  root :to => 'main#index'

  match "/search", :to => 'main#search'
  match "/loading", :to => 'main#loading'

  match '/mac', :to => 'main#mac'
end
