class CreateIndexOnSongGenres < ActiveRecord::Migration
  def change
    add_index :song_genres, :genre_id
    add_index :song_genres, [:song_id, :genre_id, :source], unique: true
  end
end
