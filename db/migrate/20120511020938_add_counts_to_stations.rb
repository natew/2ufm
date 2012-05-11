class AddCountsToStations < ActiveRecord::Migration
  def change
    add_column :stations, :broadcasts_count, :integer, :default => 0
  end
end
