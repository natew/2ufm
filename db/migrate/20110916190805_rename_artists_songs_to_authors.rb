class RenameArtistsSongsToAuthors < ActiveRecord::Migration
  def change
    rename_table :artists_songs, :authors
  end
end
