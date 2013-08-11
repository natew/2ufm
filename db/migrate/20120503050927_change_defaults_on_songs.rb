class ChangeDefaultsOnSongs < ActiveRecord::Migration
  def up
    # Song.all.each do |song|
    #   if song.name.nil? or song.artist_name.nil?
    #     song.name ||= ''
    #     song.artist_name ||= ''
    #     song.save
    #   end
    # end
  end

  def down
  end
end
