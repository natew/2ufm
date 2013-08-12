Fusefm::Application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount MailsViewer::Engine => '/delivered_mails' if Rails.env.development?

  root to: 'mains#index', as: 'home'
  get "/p-:p", to: 'mains#index'

  # Redirects
  get "/stations/:id", to: redirect("/%{id}")

  devise_for :users, controllers: {
    registrations: 'registrations',
    sessions: 'sessions',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  devise_scope :user do
    # resources :sessions, only: [:new]
    get '/my/login/(:username)', to: 'sessions#new', as: 'new_session'
  end

  get "/songs/trending(/p-:p)" => "songs#trending", as: 'songs_trending'
  get "/songs/fresh(/p-:p)" => "songs#fresh", as: 'songs_fresh'
  get "/songs/popular(/p-:p)" => "songs#popular", as: 'songs_popular'
  get "/genres/favorites" => "genres#favorites", as: 'genres_favorites'
  get "/genres/:id(/p-:p)" => "genres#show"
  get "/tags/:id(/p-:p)" => 'tags#show'

  resources :songs, only: [:index, :show]
  resources :follows, only: [:create, :destroy]
  resources :broadcasts, only: [:create, :destroy]
  # resources :comments, only: [:create, :destroy]
  resources :listens, only: [:create, :show]
  resources :actions, only: [:create]
  resources :blogs, only: [:new, :create]
  resources :tags, only: [:index, :show]

  resources :genres, only: [:index, :show] do
    member do
      get 'trending(/p-:p)' => "genres#trending", as: 'trending'
      get 'latest(/p-:p)' => "genres#latest", as: 'latest'
      get 'shuffle(/p-:p)' => "genres#shuffle", as: 'shuffle'
      get 'artists' => "genres#artists", as: 'artists'
    end
  end

  get '/browse/artists(/:genre)' => 'artists#index', as: 'artists'
  get '/browse/users(/:letter)' => 'users#index', as: 'users'
  get '/browse/blogs(/:genre)' => 'blogs#index', as: 'browse_blogs'

  resources :shares, only: [:create]
  get '/shares/inbox(/p-:p)' => 'shares#inbox'
  get '/shares/outbox(/p-:p)' => 'shares#outbox'

  get "/go/:to/:id" => "songs#go", as: :affiliate
  get "/go/amazon/:id" => "songs#go", as: :amazon_affiliate
  get "/go/itunes/:id" => "songs#go", as: :itunes_affiliate

  # Users routes
  get "/tune/:id" => "users#tune"
  get "/@:id" => "users#live"
  get '/activate/:id/:key' => 'users#activate'
  get "/navbar" => 'users#navbar'
  get '/unsubscribe/:type/:key' => 'users#unsubscribe'
  get '/my/friends' => 'users#find_friends', as: 'users_friends'
  get '/do/authorized' => 'users#authorized'
  get '/my/home(/p-:p)' => 'mains#index', as: 'users_home'
  get '/confirm/:key' => 'users#confirm'

  # Account routes
  get '/my/account' => 'account#index', as: 'account'
  get '/my/account/preferences' => 'account#preferences', as: 'account_preferences'
  get '/my/account/edit' => 'account#edit', as: 'account_edit'

  post '/my/genres' => 'users#genres'
  post "/play/:id" => "songs#play"
  post "/l/:id" => "listens#show"
  post "/songs/:id" => "songs#failed"
  post "/broadcasts/:song_id" => "broadcasts#create"
  post "/follows/:station_id" => "follows#create"
  post '/share' => 'shares#create'

  ### BELOW HERE get /:STATION_SLUG ROUTES ###

  # Root level stations access
  get "/:id(/p-:p)" => 'stations#show', as: :station
  get "/:id" => 'stations#show', as: :artist
  get "/:id" => 'stations#show', as: :blog
  get "/:id" => 'stations#show', as: :user

  resource :main, only:[], path: '/us' do
    member do
      get 'about'
      get 'legal'
      get 'privacy'
      get 'contact'
      get 'loading'
      get 'mac'
    end
  end

  get '/do/search(/:get_query)' => 'mains#search'
  get '/:id/feed/p-:p' => 'users#feed'

  resources :users, only:[], path: '/' do
    member do
      get 'following(/:type)' => 'users#following', as: 'following'
      get 'followers'
      get 'feed(/:type)(/p-:p)' => 'users#feed', as: 'feed'
    end
  end

  resources :blogs, only:[:new], path: '/' do
    member do
      get 'popular(/p-:p)' => 'blogs#popular', as: 'popular'
    end
  end

  # Artists
  resources :artists, only:[], path: '/' do
    member do
      get 'remixes_of(/p-:p)' => 'artists#remixes_of', as: 'remixes_of'
      get 'remixes_by(/p-:p)' => 'artists#remixes_by', as: 'remixes_by'
      get 'originals(/p-:p)' => 'artists#originals', as: 'originals'
      get 'popular(/p-:p)' => 'artists#popular', as: 'popular'
      get 'mashups(/p-:p)' => 'artists#mashups', as: 'mashups'
      get 'covers(/p-:p)' => 'artists#covers', as: 'covers'
      get 'features(/p-:p)' => 'artists#features', as: 'features'
      get 'productions(/p-:p)' => 'artists#productions', as: 'productions'
    end
  end
end
