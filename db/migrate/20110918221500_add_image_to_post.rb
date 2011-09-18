class AddImageToPost < ActiveRecord::Migration
  def change
    add_column :posts, :image_file_name, :string
    add_column :posts, :image_updated_at, :string
  end
end
