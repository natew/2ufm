class EstimatePlayCounts < ActiveRecord::Migration
  def up
    # Song.working.each do |song|
    #   song.play_count = Listen.where(song_id: song.id).count
    #   song.save
    # end
  end

  def down
  end
end
