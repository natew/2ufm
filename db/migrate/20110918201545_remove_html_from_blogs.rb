class RemoveHtmlFromBlogs < ActiveRecord::Migration
  def change
    remove_column :blogs, :html
  end
end
