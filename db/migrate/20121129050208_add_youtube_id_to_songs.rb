class AddYoutubeIdToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :youtube_id, :string
    add_column :songs, :description, :string
  end
end
