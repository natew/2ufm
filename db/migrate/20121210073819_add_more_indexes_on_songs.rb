class AddMoreIndexesOnSongs < ActiveRecord::Migration
  def change
    remove_index :songs, name: 'songs_index'
    remove_index :songs, [:source, :seconds, :processed, :working]
    add_index :songs, :processed
    add_index :songs, :user_broadcasts_count
    add_index :songs, :rank
    add_index :songs, :working
    add_index :songs, :published_at
    add_index :songs, [:matching_id, :id]
  end
end
