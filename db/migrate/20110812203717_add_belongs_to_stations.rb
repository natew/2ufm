class AddBelongsToStations < ActiveRecord::Migration
  def change
    add_column :stations, :blog_id, :integer
    add_column :stations, :user_id, :integer
  end
end
