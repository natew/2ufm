class AddStationToArtists < ActiveRecord::Migration
  def change
    add_column :artists, :station_id, :integer
  end
end
