class AddLastBroadcastedAtToStations < ActiveRecord::Migration
  def change
    add_column :stations, :last_broadcasted_at, :timestamp, :default => Time.now
  end
end
