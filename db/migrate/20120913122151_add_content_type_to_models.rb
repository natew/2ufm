class AddContentTypeToModels < ActiveRecord::Migration
  def change
    add_column :songs, :image_content_type, :string
    add_column :blogs, :image_content_type, :string
    add_column :artists, :image_content_type, :string
    add_column :users, :avatar_content_type, :string
  end
end
