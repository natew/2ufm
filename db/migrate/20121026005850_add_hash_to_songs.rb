class AddHashToSongs < ActiveRecord::Migration
  def add
    add_column :songs, :file_key, :string

    Song.all.each do |song|
      song.set_file_key
      song.save
    end
  end
end
