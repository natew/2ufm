class RedoIndex < ActiveRecord::Migration
  def up
    remove_index :songs, [:processed, :working, :rank, :matching_id]
    add_index :songs, [:processed, :working, :rank, :matching_id, :published_at], :name => 'songs_index'
  end

  def down
  end
end
