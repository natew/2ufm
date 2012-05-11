class AddTimestampsToStations < ActiveRecord::Migration
  def change
    add_column :stations, :created_at, :datetime, :default => Time.now
    add_column :stations, :updated_at, :datetime, :default => Time.now
  end
end
