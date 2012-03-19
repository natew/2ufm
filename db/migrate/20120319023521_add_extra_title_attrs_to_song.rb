class AddExtraTitleAttrsToSong < ActiveRecord::Migration
  def change
  	add_column :songs, :original_song, :boolean
  end
end
