class AddSongsBackOntoBlogStations < ActiveRecord::Migration
  def up
    # Song.working.each do |song|
    #   Blog.find(song.blog_id).station.broadcasts.create(song_id:song.id, created_at:song.published_at)
    # end
  end

  def down
  end
end
