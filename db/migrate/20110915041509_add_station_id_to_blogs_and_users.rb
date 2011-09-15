class AddStationIdToBlogsAndUsers < ActiveRecord::Migration
  def change
    add_column :blogs, :station_id, :integer
  end
end
