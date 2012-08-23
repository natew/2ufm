class AddOnlineToStations < ActiveRecord::Migration
  def change
    add_column :stations, :online, :timestamp
  end
end
