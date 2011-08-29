class CreateGenresStations < ActiveRecord::Migration
  def change
    create_table :genres_stations, :id => false do |t|
      t.references :genre, :station
    end
  end
end
