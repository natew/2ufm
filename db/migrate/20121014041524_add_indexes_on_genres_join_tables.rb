class AddIndexesOnGenresJoinTables < ActiveRecord::Migration
  def change
    add_index :artists, [:station_slug]
    add_index :stations, [:slug]
    add_index :blogs, [:station_slug]
  end
end
