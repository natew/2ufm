class CountSongsByArtists < ActiveRecord::Migration
  def up
    # Artist.all.each do |artist|
    #   artist.song_count = Author.select('artist_id, song_id').where(artist_id: artist.id).group('song_id, artist_id').order('song_id').length
    #   artist.save
    # end
  end

  def down
  end
end
