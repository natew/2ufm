class ArtistGenre < ActiveRecord::Base
  belongs_to :genre
  belongs_to :artist

  attr_accessible :genre_id, :artist_id

  after_create :create_song_genres
  before_destroy :destroy_song_genres

  private

  def destroy_song_genres
    SongGenre.where(song_id: artist.songs.select('songs.id').map(&:id), genre_id: genre_id).destroy_all
  end

  def create_song_genres
    artist.songs.each do |song|
        song.add_artist_genres
    end
  end
end
