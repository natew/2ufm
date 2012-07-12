class GiveMatchingIdToNulls < ActiveRecord::Migration
  def up
    Song.where('matching_id is null').each do |song|
      song.update_matching_songs
      song.save
    end
  end

  def down
  end
end
