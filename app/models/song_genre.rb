class SongGenre < ActiveRecord::Base
  belongs_to :song
  belongs_to :genre

  attr_accessible :source, :song_id, :genre_id

  scope :from_artist, where(source: 'artist')
  scope :from_blog, where(source: 'blog')
  scope :from_tag, where(source: 'tag')
  scope :from_post, where(source: 'post')

end
