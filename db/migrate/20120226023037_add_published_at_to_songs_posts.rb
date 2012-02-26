class AddPublishedAtToSongsPosts < ActiveRecord::Migration
  def change
  	add_column :songs, :published_at, :timestamp, :defualt => Time.now
  	add_column :posts, :published_at, :timestamp, :defualt => Time.now
  end
end
