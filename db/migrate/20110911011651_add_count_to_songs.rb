class AddCountToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :stations_count, :integer, :default => 0
  end
end
