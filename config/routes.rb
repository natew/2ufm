Fusefm::Application.routes.draw do
  ActiveAdmin.routes(self)
  devise_for :admin_users, ActiveAdmin::Devise.config
  devise_for :users
  
  match "/users", :to => "users#index"
  match "/songs/popular", :to => "songs#popular"

  resources :blogs, :posts, :songs, :stations, :favorites

  root :to => 'main#index'
  match "/search/:query", :to => 'main#search'

end
