class UpdateCountsOnStations < ActiveRecord::Migration
  def up
    Station.reset_column_information
    Station.all.each do |station|
      Station.update_counters station.id, :broadcasts_count => station.broadcasts.length
    end
  end

  def down
  end
end
