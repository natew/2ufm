class ChangeStations < ActiveRecord::Migration
  def change
    add_column :stations, :artist_id, :integer
    add_column :stations, :user_id, :integer
    add_column :stations, :blog_id, :integer
    
    remove_column :stations, :name
    remove_column :stations, :slug
    remove_column :stations, :image_file_name
    remove_column :stations, :image_updated_at
    remove_column :stations, :created_at
    remove_column :stations, :updated_at
  end
end
