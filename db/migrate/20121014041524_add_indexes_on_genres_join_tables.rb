class AddIndexesOnGenresJoinTables < ActiveRecord::Migration
  def change
    add_index :genres_users, [:user_id, :genre_id], :unique => true
    add_index :blogs_genres, [:genre_id, :blog_id], :unique => true
    add_index :artists_genres, [:genre_id, :artist_id], :unique => true
  end
end
