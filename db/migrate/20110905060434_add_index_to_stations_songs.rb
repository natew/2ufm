class AddIndexToStationsSongs < ActiveRecord::Migration
  def change
    add_index :songs_stations, [:song_id, :station_id], :unique => true
  end
end
