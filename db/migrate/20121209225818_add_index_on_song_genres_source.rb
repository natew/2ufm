class AddIndexOnSongGenresSource < ActiveRecord::Migration
  def change
    add_index :songs, :matching_id
    add_index :song_genres, [:id, :source]
    # add_index :songs, [:processed, :working, :source, :seconds, :category, :id, :matching_id]
  end
end
