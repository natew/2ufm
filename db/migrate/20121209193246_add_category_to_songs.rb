class AddCategoryToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :category, :string
    add_index :songs, :category
  end
end
