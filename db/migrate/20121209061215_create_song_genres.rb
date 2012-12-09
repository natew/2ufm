class CreateSongGenres < ActiveRecord::Migration
  def change
    create_table :song_genres do |t|
      t.references :genre, :song
      t.string :source
      t.timestamps
    end
  end
end
