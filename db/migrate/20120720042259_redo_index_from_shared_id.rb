class RedoIndexFromSharedId < ActiveRecord::Migration
  def change
    remove_index :songs, [:processed, :working, :rank, :shared_id]
    add_index :songs, [:processed, :working, :rank, :matching_id]
  end
end
