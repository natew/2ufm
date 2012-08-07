class UpdateSongRanks < ActiveRecord::Migration
  def up
    Song.all.each do |song|
      song.set_rank
      song.save
    end
  end

  def down
  end
end
