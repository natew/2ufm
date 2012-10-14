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
  has_and_belongs_to_many :genres

  acts_as_url :name, :url_attribute => :slug, :allow_duplicates => false

  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }

  before_validation :make_station, :on => :create
  after_create :get_info

  serialize :urls

  validates :name, presence: true
  validates :station, presence: true
  validates_with SlugValidator

  scope :for_linking, joins(:authors).select('artists.id, artists.slug, artists.name, authors.role as role')

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
    if echo_artist
      id = echo_artist['response']['artists'][0]['id']
      if id
        terms_url = "http://developer.echonest.com/api/v4/artist/terms?api_key=#{Yetting.echonest_api_key}&id=#{id}&format=json"
        echo_terms = HTTParty.get(terms_url)
        if echo_terms
          logger.info echo_terms
          echo_terms['response']['terms'].each do |term|
            genres.push Genre.map_name(term['name']).titleize unless term['frequency'] < 0.1 or term['weight'] < 0.25
          end
        end
      end
    end
    genres
  end

  def update_genres
    genres = get_genres
    genres.each do |add_genre|
      genre = Genre.find_by_name(add_genre)
      self.genres << genre if genre
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
        self.image = UrlTempfile.new(artist.images.first.uri) unless artist.images.nil?
        self.urls  = artist.urls unless artist.urls.nil?
        self.save
      else
        logger.info "No information found"
      end
    rescue Exception => e
      # Artist not found!
      logger.error "Error getting discogs information."
    end
  end

  def make_station
    station = self.create_station(title:name)
    self.station_slug = station.slug
  end
end
