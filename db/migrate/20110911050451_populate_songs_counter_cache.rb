class PopulateSongsCounterCache < ActiveRecord::Migration
  def up
    Song.reset_column_information
    Song.find(:all).each do |s|
      Song.update_counters s.id, :broadcasts_count => s.broadcasts.length
    end
  end

  def down
  end
end
