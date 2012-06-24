class AddIndexToSongs < ActiveRecord::Migration
  def change
    add_index :songs, :shared_id
  end
end
