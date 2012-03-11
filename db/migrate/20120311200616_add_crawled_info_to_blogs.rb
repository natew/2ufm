class AddCrawledInfoToBlogs < ActiveRecord::Migration
  def change
  	add_column :blogs, :crawl_started_at, :timestamp
  	add_column :blogs, :crawl_finished_at, :timestamp
  	add_column :blogs, :crawled_pages, :integer, :default => 0
  end
end
