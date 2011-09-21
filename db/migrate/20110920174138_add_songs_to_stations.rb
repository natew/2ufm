class AddSongsToStations < ActiveRecord::Migration
  def change
    Station.where('id > ?',11).destroy_all
    
    User.all.each do |i|
      i.create_station
    end
    
    Artist.all.each do |i|
      s = i.create_station
    end
    
    Blog.all.each do |i|
      s = i.create_station
    end
  end
end
