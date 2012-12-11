require 'discogs'

class Artist < ActiveRecord::Base
  include AttachmentHelper
  include PaperclipExtensions
  include SlugExtensions
  include CommonScopes

  has_one    :station, :dependent => :destroy
  has_many   :broadcasts, :through => :songs
  has_many   :stations, :through => :broadcasts
  has_many   :authors, :dependent => :destroy
  has_many   :songs, :through => :authors, :extend => SongExtensions
  has_many   :artist_genres
  has_many   :genres, :through => :artist_genres

  acts_as_url :name, :url_attribute => :slug, :allow_duplicates => false

  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }

  before_validation :make_station, :on => :create
  after_create :get_info

  serialize :urls

  validates :name, presence: true
  validates :station, presence: true
  validates_with SlugValidator

  scope :has_image, where('artists.image_updated_at is not null')
  scope :for_linking, joins(:authors).select('artists.id, artists.slug, artists.name, authors.role as role')

  rails_admin do
    list do
      field :id
      field :name
      field :created_at
    end
  end

  def to_param
    station_slug
  end

  def to_playlist_json
    self.to_json(:only => [:id, :slug, :name])
  end

  def get_title
    name
  end

  # returns station slug
  def url
    station.slug
  end

  def get_info
    delay(:priority => 5).update_genres
    delay(:priority => 6).get_discogs_info
  end

  def station_songs_count
    station.songs_count
  end

  def get_genres
    genres = []
    url_name = Rack::Utils.escape(name)
    url = "http://developer.echonest.com/api/v4/artist/search?api_key=#{Yetting.echonest_api_key}&name=#{url_name}"
    echo_artist = HTTParty.get(url)
    return unless echo_artist
    echo_artist_response = echo_artist['response']
    return unless echo_artist_response
    artists = echo_artist_response['artists']
    return unless artists
    first_artist = artists[0]
    return unless first_artist
    id = first_artist['id']
    terms_url = "http://developer.echonest.com/api/v4/artist/terms?api_key=#{Yetting.echonest_api_key}&id=#{id}&format=json"
    echo_terms = HTTParty.get(terms_url)
    return unless echo_terms
    echo_terms_response = echo_terms['response']
    return unless echo_terms_response
    terms = echo_terms_response['terms']
    return unless terms
    logger.info terms.to_yaml
    terms.each do |term|
      genres.push Genre.map_name(term['name']).titleize unless term['frequency'] < 0.1 or term['weight'] < 0.25
    end
    genres
  end

  def update_genres
    logger.info "Updating genres for #{id} - #{name}"
    got_genres = get_genres
    return unless got_genres
    self.genres.destroy_all
    got_genres.each do |add_genre|
      genre = Genre.find_or_create_by_name(add_genre)
      begin
        self.genres << genre if genre
      rescue ActiveRecord::RecordNotUnique => e
        logger.error "Already exists"
      end
    end
    self.genres
  end

  def get_discogs_info
    begin
      logger.info "Getting info for #{name}"
      wrapper = Discogs::Wrapper.new("fusefm")
      artist  = wrapper.get_artist(name)

      if !artist.nil?
        logger.info "Info found"
        self.image = UrlTempfile.new(artist.images.first.uri) unless image.exists? or artist.images.nil?
        self.urls  = artist.urls unless artist.urls.nil?
        self.about = artist.profile unless artist.profile.nil?
        self.save
      else
        logger.info "No information found"
      end
    rescue Exception => e
      # Artist not found!
      logger.error "Error getting discogs information."
      logger.error artist.to_yaml
      logger.error e.inspect
      logger.error e.backtrace.join("\n")
    end
  end

  def make_station
    station = self.create_station(title:name)
    self.station_slug = station.slug
  end
end
