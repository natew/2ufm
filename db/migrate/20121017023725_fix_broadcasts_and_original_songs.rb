class FixBroadcastsAndOriginalSongs < ActiveRecord::Migration
  def up
    Song.working.each do |song|
      song.fix_broadcasts
      song.determine_if_original
    end
  end

  def down
  end
end
