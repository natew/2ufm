class AddSongsToStationsAgain < ActiveRecord::Migration
  def change
    Song.working.each do |s|
      s.add_to_stations
    end
  end
end
