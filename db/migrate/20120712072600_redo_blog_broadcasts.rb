class RedoBlogBroadcasts < ActiveRecord::Migration
  def up
    Song.skip_callback(:save, :before, :set_rank)
    Broadcast.blog_broadcasts.destroy_all
    Song.working.each do |song|
      song.add_to_blog_station
      song.save
    end
    Song.set_callback(:save, :before, :set_rank)
  end

  def down
  end
end
