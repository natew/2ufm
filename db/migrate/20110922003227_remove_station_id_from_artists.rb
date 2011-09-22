class RemoveStationIdFromArtists < ActiveRecord::Migration
  def change
    remove_column :artists, :station_id
  end
end
