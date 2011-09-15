class RemoveUserIdFromStations < ActiveRecord::Migration
  def change
    remove_column :stations, :user_id
    remove_column :stations, :blog_id
  end
end
