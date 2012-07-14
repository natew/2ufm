class UpdateMatchingSongs < ActiveRecord::Migration
  def up
    Song.working.each do |song|
      song.update_matching_songs
      song.save
    end
  end

  def down
  end
end
