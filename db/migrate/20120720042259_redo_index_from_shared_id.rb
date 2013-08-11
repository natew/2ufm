class RedoIndexFromSharedId < ActiveRecord::Migration
  def change
    add_index :songs, [:processed, :working, :rank, :matching_id]
  end
end
