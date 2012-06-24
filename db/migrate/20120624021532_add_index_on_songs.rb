class AddIndexOnSongs < ActiveRecord::Migration
  def change
    add_index :songs, [:processed, :working, :rank, :shared_id]
  end
end
