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

  after_create :add_artist_roles
  after_destroy :remove_artist_roles

  def role?(type)
    role == type.to_s
  end

  def add_artist_roles
    if artist
      self.artist['has_' + ROLES_TO_POSSESIVE[role]] = true
      self.artist.save
    end
  end

  def remove_artist_roles
    if artist
      self.artist['has_' + ROLES_TO_POSSESIVE[role]] = Author.where(:artist_id => artist_id, :role => role).exists?
      self.artist.save
    end
  end
end
