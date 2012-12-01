class AddIndexOnSongsSource < ActiveRecord::Migration
  def change
    add_index :songs, [:source]
    add_index :songs, [:seconds]
    add_index :songs, [:source, :seconds, :processed, :working]
  end
end
