class RemoveWorkingFromBlogs < ActiveRecord::Migration
  def change
  	remove_column :blogs, :working
  end
end
