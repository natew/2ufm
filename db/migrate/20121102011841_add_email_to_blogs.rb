class AddEmailToBlogs < ActiveRecord::Migration
  def change
    add_column :blogs, :email, :string
  end
end
