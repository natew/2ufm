class AddSoundcloudTagsUpdatedAtToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :soundcloud_tags_updated_at, :timestamp
  end
end
