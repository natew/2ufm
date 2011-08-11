class AddSlugsToModels < ActiveRecord::Migration
  def change
    add_column :songs, :slug, :string
    add_column :posts, :slug, :string
    add_column :blogs, :slug, :string
    add_column :artists, :slug, :string
    add_column :users, :slug, :string
    add_column :genres, :slug, :string
  end
end
