class AddAttachmentsToModels < ActiveRecord::Migration
  def change
    add_column :users, :avatar_file_name, :string
    add_column :users, :avatar_updated_at, :datetime
    
    add_column :blogs, :image_file_name, :string
    add_column :blogs, :image_updated_at, :datetime
    
    add_column :stations, :image_file_name, :string
    add_column :stations, :image_updated_at, :datetime
    
    add_column :songs, :image_file_name, :string
    add_column :songs, :image_updated_at, :datetime
  end
end
