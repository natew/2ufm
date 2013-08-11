class AddIndexToBroadcasts < ActiveRecord::Migration
  def change
    # add_index :broadcasts, [:song_id, :station_id], :unique => true
  end
end
