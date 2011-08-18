class CreateSongs < ActiveRecord::Migration
  def change
    create_table :songs do |t|
      t.string :name, :artist, :album, :genre, :album_artist, :url, :link_text
      t.integer :plays, :size, :track_number, :bitrate, :length, :shared_id
      t.references :blog, :post, :artist, :album  # original blog
      t.boolean :vbr
      
      t.timestamps
    end
  end
end
