class Station < ActiveRecord::Base
  has_and_belongs_to_many :genres
  belongs_to :user
  belongs_to :artist
  belongs_to :blog
  has_many   :broadcasts, :dependent => :destroy
  has_many   :songs, :through => :broadcasts, :extend => SongExtensions
  has_many   :follows
  has_many   :artists, :through => :songs, :uniq => true
  has_many   :blogs, :through => :songs, :uniq => true

  scope :blog_station, where('stations.blog_id is not NULL')
  scope :artist_station, where('stations.artist_id is not NULL')
  scope :user_station, where('stations.user_id is not NULL')

  # Whitelist mass-assignment attributes
  attr_accessible :id, :description, :title, :slug

  # Slug
  acts_as_url :title, :url_attribute => :slug

  # Validations
  validates_with SlugValidator

  def to_param
    slug
  end

  def user_broadcasts
    broadcasts.where(:parent => 'user')
  end

  def self.popular(opts={})
    p = Station.new(:id => 1, :title => 'Popular Today', :slug => 'songs')
  end

  def self.newest(opts={})
    p = Station.new(:id => 0, :title => 'Newest', :slug => 'songs-new')
  end

  def image
    get_parent.image
  end

  def description
    parent = get_parent
    parent.description if parent.respond_to?('description')
  end

  def to_api_json
    self.to_json(:only => [:id, :slug, :title], :include => {
      :songs => {
        :only => [
          :absolute_url,
          :artist_name,
          :blog_id,
          :blog_name,
          :id,
          :name,
          :rank,
          :url,
          :image
        ]
      }
    })
  end

  def to_playlist_json
    # TODO image from parent
    self.to_json(:only => [:id, :slug, :title])
  end

  # def to_playlist_json
  #   self.to_json(:only => [:id, :slug, :title], :include => {
  #     :songs => {
  #       :only => [
  #         :artist_name,
  #         :id,
  #         :name,
  #         :url,
  #         :image
  #       ]
  #     }
  #   })
  # end

  def has_songs?
    songs.size > 0
  end

  def song_exists?(song_id)
    Broadcast.where('song_id = ? and station_id = ?', song_id, id).exists?
  end

  private

  def get_parent
    if !blog_id.nil?
      blog
    elsif !artist_id.nil?
      artist
    elsif !user_id.nil?
      user
    end
  end
end
