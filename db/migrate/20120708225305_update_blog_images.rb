class UpdateBlogImages < ActiveRecord::Migration
  def up
    Blog.all.each do |blog|
      blog.set_screenshot
      blog.save
    end
  end

  def down
  end
end
