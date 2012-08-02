class CreateStationSlugs < ActiveRecord::Migration
  def up
    Station.all.each do |station|
      puts station.title
      station.generate_parent_station_slug
    end
  end

  def down
  end
end
