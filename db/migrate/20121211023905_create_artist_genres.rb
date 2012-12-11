class CreateArtistGenres < ActiveRecord::Migration
  def change
    rename_table :artists_genres, :artist_genres
  end
end
