class SongGenre < ActiveRecord::Base
  belongs_to :song
  belongs_to :genre

  attr_accessible :source, :song_id, :genre_id
end
