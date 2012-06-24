class RemoveExtraBlogStations < ActiveRecord::Migration
  def up
    Blog.all.each do |blog|
      real_station = blog.station
      Station.where(:blog_id => blog.id).where('id NOT IN (?)', blog.station).destroy_all
    end
  end

  def down
  end
end
