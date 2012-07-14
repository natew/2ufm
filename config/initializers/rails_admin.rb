# RailsAdmin config file. Generated on July 14, 2012 11:38
# See github.com/sferik/rails_admin for more informations

RailsAdmin.config do |config|

  # If your default_local is different from :en, uncomment the following 2 lines and set your default locale here:
  # require 'i18n'
  # I18n.default_locale = :de

  config.current_user_method { current_user } # auto-generated

  # If you want to track changes on your models:
  # config.audit_with :history, User

  # Or with a PaperTrail: (you need to install it first)
  # config.audit_with :paper_trail, User

  # Set the admin name here (optional second array element will appear in a beautiful RailsAdmin red ©)
  config.main_app_name = ['Fusefm', 'Admin']
  # or for a dynamic name:
  # config.main_app_name = Proc.new { |controller| [Rails.application.engine_name.titleize, controller.params['action'].titleize] }

  config.authorize_with :cancan


  #  ==> Global show view settings
  # Display empty fields in show views
  # config.compact_show_view = false

  #  ==> Global list view settings
  # Number of default rows per-page:
  # config.default_items_per_page = 20

  #  ==> Included models
  # Add all excluded models here:
  # config.excluded_models = [Activity, Artist, Author, Blog, Broadcast, Comment, Follow, Genre, Listen, Post, Song, Station, User]

  # Add models here if you want to go 'whitelist mode':
  # config.included_models = [Activity, Artist, Author, Blog, Broadcast, Comment, Follow, Genre, Listen, Post, Song, Station, User]

  # Application wide tried label methods for models' instances
  # config.label_methods << :description # Default is [:name, :title]

  #  ==> Global models configuration
  # config.models do
  #   # Configuration here will affect all included models in all scopes, handle with care!
  #
  #   list do
  #     # Configuration here will affect all included models in list sections (same for show, export, edit, update, create)
  #
  #     fields_of_type :date do
  #       # Configuration here will affect all date fields, in the list section, for all included models. See README for a comprehensive type list.
  #     end
  #   end
  # end
  #
  #  ==> Model specific configuration
  # Keep in mind that *all* configuration blocks are optional.
  # RailsAdmin will try his best to provide the best defaults for each section, for each field.
  # Try to override as few things as possible, in the most generic way. Try to avoid setting labels for models and attributes, use ActiveRecord I18n API instead.
  # Less code is better code!
  # config.model MyModel do
  #   # Cross-section field configuration
  #   object_label_method :name     # Name of the method called for pretty printing an *instance* of ModelName
  #   label 'My model'              # Name of ModelName (smartly defaults to ActiveRecord's I18n API)
  #   label_plural 'My models'      # Same, plural
  #   weight -1                     # Navigation priority. Bigger is higher.
  #   parent OtherModel             # Set parent model for navigation. MyModel will be nested below. OtherModel will be on first position of the dropdown
  #   navigation_label              # Sets dropdown entry's name in navigation. Only for parents!
  #   # Section specific configuration:
  #   list do
  #     filters [:id, :name]  # Array of field names which filters should be shown by default in the table header
  #     items_per_page 100    # Override default_items_per_page
  #     sort_by :id           # Sort column (default is primary key)
  #     sort_reverse true     # Sort direction (default is true for primary key, last created first)
  #     # Here goes the fields configuration for the list view
  #   end
  # end

  # Your model's configuration, to help you get started:

  # All fields marked as 'hidden' won't be shown anywhere in the rails_admin unless you mark them as visible. (visible(true))

  # config.model Activity do
  #   # Found associations:
  #     configure :user, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :type, :string
  #     configure :description, :string
  #     configure :user_id, :integer         # Hidden
  #     configure :station_id, :integer
  #     configure :song_id, :integer
  #     configure :created_at, :datetime
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Artist do
  #   # Found associations:
  #     configure :station, :has_one_association
  #     configure :broadcasts, :has_many_association
  #     configure :stations, :has_many_association
  #     configure :authors, :has_many_association
  #     configure :songs, :has_many_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :name, :string
  #     configure :about, :text
  #     configure :created_at, :datetime
  #     configure :updated_at, :datetime
  #     configure :slug, :string
  #     configure :image_file_name, :string         # Hidden
  #     configure :image_updated_at, :string         # Hidden
  #     configure :image, :paperclip
  #     configure :urls, :serialized
  #     configure :has_remixes, :boolean
  #     configure :has_mashups, :boolean
  #     configure :has_covers, :boolean
  #     configure :has_originals, :boolean
  #     configure :has_productions, :boolean
  #     configure :has_features, :boolean
  #     configure :song_count, :integer
  #     configure :station_slug, :string   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Author do
  #   # Found associations:
  #     configure :artist, :belongs_to_association
  #     configure :song, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :artist_id, :integer         # Hidden
  #     configure :song_id, :integer         # Hidden
  #     configure :role, :string   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Blog do
  #   # Found associations:
  #     configure :station, :has_one_association
  #     configure :songs, :has_many_association
  #     configure :posts, :has_many_association
  #     configure :genres, :has_and_belongs_to_many_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :name, :string
  #     configure :description, :text
  #     configure :url, :string
  #     configure :feed_url, :string
  #     configure :feed_updated_at, :datetime
  #     configure :created_at, :datetime
  #     configure :updated_at, :datetime
  #     configure :slug, :string
  #     configure :image_file_name, :string         # Hidden
  #     configure :image_updated_at, :datetime         # Hidden
  #     configure :image, :paperclip
  #     configure :crawl_started_at, :datetime
  #     configure :crawl_finished_at, :datetime
  #     configure :crawled_pages, :integer
  #     configure :station_slug, :string   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Broadcast do
  #   # Found associations:
  #     configure :station, :belongs_to_association
  #     configure :song, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :station_id, :integer         # Hidden
  #     configure :song_id, :integer         # Hidden
  #     configure :created_at, :datetime
  #     configure :parent, :string   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Comment do
  #   # Found associations:
  #     configure :commentable, :polymorphic_association
  #     configure :user, :belongs_to_association
  #     configure :parent, :belongs_to_association
  #     configure :children, :has_many_association
  #     configure :votes, :has_many_association         # Hidden   #   # Found columns:
  #     configure :id, :integer
  #     configure :commentable_id, :integer         # Hidden
  #     configure :commentable_type, :string         # Hidden
  #     configure :title, :string
  #     configure :body, :text
  #     configure :subject, :string
  #     configure :user_id, :integer         # Hidden
  #     configure :parent_id, :integer         # Hidden
  #     configure :lft, :integer
  #     configure :rgt, :integer
  #     configure :created_at, :datetime
  #     configure :updated_at, :datetime   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Follow do
  #   # Found associations:
  #     configure :station, :belongs_to_association
  #     configure :user, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :station_id, :integer         # Hidden
  #     configure :user_id, :integer         # Hidden   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Genre do
  #   # Found associations:
  #     configure :stations, :has_and_belongs_to_many_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :name, :string
  #     configure :slug, :string   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Listen do
  #   # Found associations:
  #     configure :song, :belongs_to_association
  #     configure :user, :belongs_to_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :shortcode, :string
  #     configure :url, :string
  #     configure :time, :integer
  #     configure :song_id, :integer         # Hidden
  #     configure :created_at, :datetime
  #     configure :updated_at, :datetime
  #     configure :user_id, :integer         # Hidden   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Post do
  #   # Found associations:
  #     configure :blog, :belongs_to_association
  #     configure :songs, :has_many_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :title, :string
  #     configure :author, :string
  #     configure :url, :string
  #     configure :content, :text
  #     configure :blog_id, :integer         # Hidden
  #     configure :songs_saved, :boolean
  #     configure :songs_updated_at, :datetime
  #     configure :created_at, :datetime
  #     configure :updated_at, :datetime
  #     configure :slug, :string
  #     configure :image_file_name, :string         # Hidden
  #     configure :image_updated_at, :string         # Hidden
  #     configure :image, :paperclip
  #     configure :published_at, :datetime
  #     configure :excerpt, :string   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Song do
  #   # Found associations:
  #     configure :blog, :belongs_to_association
  #     configure :post, :belongs_to_association
  #     configure :broadcasts, :has_many_association
  #     configure :stations, :has_many_association
  #     configure :users, :has_many_association
  #     configure :authors, :has_many_association
  #     configure :artists, :has_many_association
  #     configure :listens, :has_many_association
  #     configure :comment_threads, :has_many_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :name, :string
  #     configure :artist_name, :string
  #     configure :album_name, :string
  #     configure :genre, :string
  #     configure :album_artist, :string
  #     configure :url, :text
  #     configure :link_text, :string
  #     configure :plays, :integer
  #     configure :size, :integer
  #     configure :track_number, :integer
  #     configure :bitrate, :integer
  #     configure :length, :integer
  #     configure :matching_id, :integer
  #     configure :blog_id, :integer         # Hidden
  #     configure :post_id, :integer         # Hidden
  #     configure :album_id, :integer
  #     configure :vbr, :boolean
  #     configure :created_at, :datetime
  #     configure :updated_at, :datetime
  #     configure :slug, :string
  #     configure :image_file_name, :string         # Hidden
  #     configure :image_updated_at, :datetime         # Hidden
  #     configure :image, :paperclip
  #     configure :processed, :boolean
  #     configure :file_file_name, :string         # Hidden
  #     configure :file_updated_at, :string         # Hidden
  #     configure :file, :paperclip
  #     configure :matching_count, :integer
  #     configure :working, :boolean
  #     configure :published_at, :datetime
  #     configure :absolute_url, :text
  #     configure :rank, :float
  #     configure :original_song, :boolean
  #     configure :failures, :integer
  #     configure :user_broadcasts_count, :integer
  #     configure :linked_title, :text
  #     configure :waveform_file_name, :string         # Hidden
  #     configure :waveform_updated_at, :datetime         # Hidden
  #     configure :waveform, :paperclip
  #     configure :source, :string
  #     configure :soundcloud_id, :integer
  #     configure :play_count, :integer
  #     configure :blog_broadcasts_count, :integer
  #     configure :match_name, :string   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model Station do
  #   # Found associations:
  #     configure :artist, :belongs_to_association
  #     configure :user, :belongs_to_association
  #     configure :blog, :belongs_to_association
  #     configure :genres, :has_and_belongs_to_many_association
  #     configure :broadcasts, :has_many_association
  #     configure :songs, :has_many_association
  #     configure :follows, :has_many_association
  #     configure :followers, :has_many_association
  #     configure :artists, :has_many_association
  #     configure :blogs, :has_many_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :title, :string
  #     configure :artist_id, :integer         # Hidden
  #     configure :user_id, :integer         # Hidden
  #     configure :blog_id, :integer         # Hidden
  #     configure :follows_count, :integer
  #     configure :slug, :string
  #     configure :broadcasts_count, :integer
  #     configure :created_at, :datetime
  #     configure :updated_at, :datetime
  #     configure :last_broadcasted_at, :datetime
  #     configure :promo, :boolean   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
  # config.model User do
  #   # Found associations:
  #     configure :stations, :has_many_association
  #     configure :station, :has_one_association
  #     configure :activities, :has_many_association
  #     configure :follows, :has_many_association
  #     configure :songs, :has_many_association   #   # Found columns:
  #     configure :id, :integer
  #     configure :email, :string
  #     configure :password, :password         # Hidden
  #     configure :password_confirmation, :password         # Hidden
  #     configure :reset_password_token, :string         # Hidden
  #     configure :reset_password_sent_at, :datetime
  #     configure :remember_created_at, :datetime
  #     configure :sign_in_count, :integer
  #     configure :current_sign_in_at, :datetime
  #     configure :last_sign_in_at, :datetime
  #     configure :current_sign_in_ip, :string
  #     configure :last_sign_in_ip, :string
  #     configure :confirmation_token, :string
  #     configure :confirmed_at, :datetime
  #     configure :confirmation_sent_at, :datetime
  #     configure :failed_attempts, :integer
  #     configure :unlock_token, :string
  #     configure :locked_at, :datetime
  #     configure :full_name, :string
  #     configure :location, :string
  #     configure :url, :string
  #     configure :follower_notifications, :boolean
  #     configure :newsletter, :boolean
  #     configure :created_at, :datetime
  #     configure :updated_at, :datetime
  #     configure :slug, :string
  #     configure :avatar_file_name, :string         # Hidden
  #     configure :avatar_updated_at, :datetime         # Hidden
  #     configure :avatar, :paperclip
  #     configure :username, :string
  #     configure :station_id, :integer         # Hidden
  #     configure :bio, :text
  #     configure :role, :string
  #     configure :last_visited, :string
  #     configure :last_station, :integer
  #     configure :last_song, :integer
  #     configure :station_slug, :string   #   # Sections:
  #   list do; end
  #   export do; end
  #   show do; end
  #   edit do; end
  #   create do; end
  #   update do; end
  # end
end
