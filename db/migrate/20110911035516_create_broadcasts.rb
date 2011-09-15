class CreateBroadcasts < ActiveRecord::Migration
  def change
    rename_table :songs_stations, :broadcasts
  end
end
