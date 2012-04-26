class RemoveSongsBroadcastsCount < ActiveRecord::Migration
  def change
    remove_column :songs, :broadcasts_count
  end
end
