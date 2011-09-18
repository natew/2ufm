class RemoveStationFromBlog < ActiveRecord::Migration
  def change
    remove_column :blogs, :station_id
  end
end
