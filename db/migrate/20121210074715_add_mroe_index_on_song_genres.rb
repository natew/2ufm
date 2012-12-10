class AddMroeIndexOnSongGenres < ActiveRecord::Migration
  def change
    add_index :song_genres, [:song_id, :genre_id, :source]
  end
end
