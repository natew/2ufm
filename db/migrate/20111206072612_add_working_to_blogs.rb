class AddWorkingToBlogs < ActiveRecord::Migration
  def change
    add_column :blogs, :working, :boolean
  end
end
