class GenresArtists < ActiveRecord::Migration
  def change
    create_table :artists_genres do |t|
      t.references :genre, :artist
    end
  end
end
