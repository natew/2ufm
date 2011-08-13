class CreateStationsSongs < ActiveRecord::Migration
  def change
    create_table :stations_songs, :id => false do |t|
      t.references :station, :song
    end
  end
end
