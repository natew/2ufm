class ReaddToStationsInLastWeek < ActiveRecord::Migration
  def up
    Song.where("created_at > ?", 1.week.ago).processed.each do |song|
      song.add_to_stations
    end
  end

  def down
  end
end
