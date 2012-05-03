class RemoveFeedFromBlogs < ActiveRecord::Migration
  def up
    remove_column :blogs, :feed
    remove_column :blogs, :cms
    remove_column :blogs, :css_post
    remove_column :blogs, :css_title
    remove_column :blogs, :last_spidered
  end
end
