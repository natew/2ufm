# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120305045224) do

  create_table "activities", :force => true do |t|
    t.string   "type"
    t.string   "description"
    t.integer  "user_id"
    t.integer  "station_id"
    t.integer  "song_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "artists", :force => true do |t|
    t.string   "name"
    t.text     "about"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.string   "image_file_name"
    t.string   "image_updated_at"
    t.text     "urls"
  end

  create_table "authors", :force => true do |t|
    t.integer "artist_id"
    t.integer "song_id"
    t.string  "role",      :default => "original"
  end

  create_table "blogs", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.text     "feed"
    t.string   "url"
    t.string   "feed_url"
    t.datetime "feed_updated_at"
    t.datetime "last_spidered"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cms"
    t.string   "css_post"
    t.string   "css_title"
    t.string   "slug"
    t.string   "image_file_name"
    t.datetime "image_updated_at"
    t.boolean  "working"
  end

  create_table "blogs_genres", :id => false, :force => true do |t|
    t.integer "blog_id"
    t.integer "genre_id"
  end

  create_table "broadcasts", :force => true do |t|
    t.integer  "station_id"
    t.integer  "song_id"
    t.datetime "created_at"
  end

  add_index "broadcasts", ["song_id", "station_id"], :name => "index_broadcasts_on_song_id_and_station_id", :unique => true
  add_index "broadcasts", ["song_id", "station_id"], :name => "index_songs_stations_on_song_id_and_station_id", :unique => true

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "follows", :force => true do |t|
    t.integer "station_id"
    t.integer "user_id"
  end

  add_index "follows", ["user_id", "station_id"], :name => "index_follows_on_user_id_and_station_id", :unique => true

  create_table "genres", :force => true do |t|
    t.string "name"
    t.string "slug"
  end

  create_table "genres_stations", :id => false, :force => true do |t|
    t.integer "genre_id"
    t.integer "station_id"
  end

  create_table "listens", :force => true do |t|
    t.string   "shortcode"
    t.string   "url"
    t.integer  "time",       :default => 0
    t.integer  "song_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "posts", :force => true do |t|
    t.string   "title"
    t.string   "author"
    t.string   "url"
    t.text     "content"
    t.integer  "blog_id"
    t.boolean  "songs_saved"
    t.datetime "songs_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.string   "image_file_name"
    t.string   "image_updated_at"
    t.datetime "published_at"
  end

  create_table "socialite_facebook_identities", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "socialite_identities", :force => true do |t|
    t.integer  "user_id"
    t.integer  "api_id"
    t.string   "api_type"
    t.string   "unique_id",  :null => false
    t.string   "provider",   :null => false
    t.text     "auth_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "socialite_identities", ["api_id", "api_type"], :name => "index_socialite_identities_on_api_id_and_api_type"
  add_index "socialite_identities", ["provider", "unique_id"], :name => "index_socialite_identities_on_provider_and_unique_id", :unique => true
  add_index "socialite_identities", ["user_id", "provider"], :name => "index_socialite_identities_on_user_id_and_provider", :unique => true
  add_index "socialite_identities", ["user_id"], :name => "index_socialite_identities_on_user_id"

  create_table "socialite_users", :force => true do |t|
    t.string   "remember_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "songs", :force => true do |t|
    t.string   "name"
    t.string   "artist_name"
    t.string   "album_name"
    t.string   "genre"
    t.string   "album_artist"
    t.text     "url"
    t.string   "link_text"
    t.integer  "plays"
    t.integer  "size"
    t.integer  "track_number"
    t.integer  "bitrate"
    t.integer  "length"
    t.integer  "shared_id"
    t.integer  "blog_id"
    t.integer  "post_id"
    t.integer  "album_id"
    t.boolean  "vbr"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.string   "image_file_name"
    t.datetime "image_updated_at"
    t.boolean  "processed",        :default => false
    t.integer  "broadcasts_count", :default => 0
    t.string   "file_file_name"
    t.string   "file_updated_at"
    t.integer  "shared_count",     :default => 0
    t.boolean  "working",          :default => false
    t.datetime "published_at"
    t.string   "absolute_url"
  end

  create_table "stations", :force => true do |t|
    t.string  "title"
    t.integer "artist_id"
    t.integer "user_id"
    t.integer "blog_id"
    t.integer "follows_count", :default => 0
    t.string  "slug"
  end

  create_table "stations_songs", :id => false, :force => true do |t|
    t.integer "station_id"
    t.integer "song_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "",     :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "",     :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                       :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "full_name"
    t.string   "location"
    t.string   "url"
    t.boolean  "follower_notifications"
    t.boolean  "newsletter"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.string   "avatar_file_name"
    t.datetime "avatar_updated_at"
    t.string   "username"
    t.integer  "station_id"
    t.text     "bio"
    t.string   "role",                                  :default => "user"
    t.string   "last_visited"
    t.integer  "last_station"
    t.integer  "last_song"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
