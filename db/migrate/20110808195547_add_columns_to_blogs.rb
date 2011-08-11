class AddColumnsToBlogs < ActiveRecord::Migration
  def change
    add_column :blogs, :cms, :string
    add_column :blogs, :css_post, :string
    add_column :blogs, :css_title, :string
  end
end
