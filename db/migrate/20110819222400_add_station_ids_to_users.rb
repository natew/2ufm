class AddStationIdsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :station_id, :integer
  end
end
