class UpdateMatchingIds < ActiveRecord::Migration
  def up
    Song.working.each do |song|
      song.delayed_update_matching_songs
    end
  end

  def down
  end
end
