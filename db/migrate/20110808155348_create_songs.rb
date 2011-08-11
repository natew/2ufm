class CreateSongs < ActiveRecord::Migration
  def change
    create_table :songs do |t|
      t.string :name, :artist, :album, :genre, :album_artist, :url
      t.integer :plays, :size, :track_number, :bitrate, :length
      t.references :blog, :post, :artist, :album  # original blog
      t.boolean :vrb
      
      t.timestamps
    end
  end
end
