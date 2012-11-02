class AddActiveToBlogs < ActiveRecord::Migration
  def up
    add_column :blogs, :active, :boolean, :default => false

    Blog.all.each do |blog|
      blog.update_attributes(active:true)
    end
  end
end
