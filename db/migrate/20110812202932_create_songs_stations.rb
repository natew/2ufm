class CreateSongsStations < ActiveRecord::Migration
  def change
    create_table :songs_stations, :id => false do |t|
      t.references :station, :song
    end

  end
end
