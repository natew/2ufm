class Author < ActiveRecord::Base
  ROLES = %w[original remixer featured producer cover mashup]
  ROLES_TO_POSSESIVE = {
    :original => 'originals',
    :remixer  => 'remixes',
    :featured => 'features',
    :producer => 'productions',
    :cover    => 'covers',
    :mashup   => 'mashups'
  }

  belongs_to :song
  belongs_to :artist

  after_create :add_artist_roles, :update_artist_songs_count
  after_destroy :remove_artist_roles, :update_artist_songs_count

  scope :with_artist, -> { joins(:artist).select('authors.role, artists.name as artist_name, artists.station_slug as artist_station_slug') }
  scope :original, -> { where(:role => 'original') }

  def role?(type)
    role == type.to_s
  end

  def add_artist_roles
    if artist
      self.artist['has_' + ROLES_TO_POSSESIVE[role.to_sym]] = true
      self.artist.save
    end
  end

  def remove_artist_roles
    if artist
      self.artist['has_' + ROLES_TO_POSSESIVE[role.to_sym]] = Author.where(:artist_id => artist_id, :role => role).exists?
      self.artist.save
    end
  end

  def update_artist_songs_count
    begin
      artist.update_attributes(song_count: artist.songs.count) if artist
    rescue
    end
  end
end
