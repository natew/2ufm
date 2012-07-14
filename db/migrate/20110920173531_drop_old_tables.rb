class DropOldTables < ActiveRecord::Migration
  def change
    drop_table :blogs_songs
    drop_table :active_admin_comments
    drop_table :albums
    drop_table :stations_users
    drop_table :taggings
    drop_table :tags
  end
end
