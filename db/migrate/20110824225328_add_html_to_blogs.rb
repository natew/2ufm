class AddHtmlToBlogs < ActiveRecord::Migration
  def change
    add_column :blogs, :html, :text
  end
end
