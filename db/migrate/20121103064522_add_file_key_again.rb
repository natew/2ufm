class AddFileKeyAgain < ActiveRecord::Migration
  def up
    add_column :songs, :file_key, :string

    Song.where('songs.file_key is null').each do |song|
      song.delay.set_file_key_and_save
    end
  end

  def down
    remove_column :songs, :file_key
  end
end
