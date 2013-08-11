class SetSourceOnSongs < ActiveRecord::Migration
  def up
    # Song.all.each do |song|
    #   source = song.set_source
    #   song.delayed_scan_and_save if source == 'soundcloud'
    # end
  end

  def down
  end
end
