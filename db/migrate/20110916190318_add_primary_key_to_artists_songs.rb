class AddPrimaryKeyToArtistsSongs < ActiveRecord::Migration
  def change
    add_column :artists_songs, :id, :primary_key
  end
end
