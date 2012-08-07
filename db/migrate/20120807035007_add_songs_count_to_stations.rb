class AddSongsCountToStations < ActiveRecord::Migration
  def change
    add_column :stations, :songs_count, :integer
  end
end
