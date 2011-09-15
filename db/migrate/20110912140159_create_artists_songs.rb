class CreateArtistsSongs < ActiveRecord::Migration
  def change
    remove_column :songs, :artist_id
    
    create_table :artists_songs, :id => false do |t|
      t.references :artist, :song
    end
  end
end
