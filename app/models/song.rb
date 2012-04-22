# encoding: UTF-8

require 'open-uri'
require 'net/http'
require 'taglib'
require 'tempfile'

class Song < ActiveRecord::Base
  include AttachmentHelper

  # Relationships
  belongs_to  :blog
  belongs_to  :post
  has_many    :broadcasts, :dependent => :destroy
  has_many    :stations, :through => :broadcasts
  has_many    :users, :through => :stations
  has_many    :authors
  has_many    :artists, :through => :authors
  has_many    :listens

  # Attachments
  has_attachment :image, styles: { large: ['800x800#'], medium: ['256x256#'], small: ['64x64#'], icon: ['32x32#'], tiny: ['24x24#'] }
  has_attachment :file

  # Validations
  validates :url, presence: true, uniqueness: true

  # Scopes
  scope :unprocessed, where(processed: false)
  scope :processed, where(processed: true)
  scope :with_blog_and_post, joins(:blog, :post)
  scope :working, where(processed: true, working: true)
  scope :newest, order('songs.created_at desc')
  scope :oldest, order('songs.published_at asc')
  scope :group_shared_order_rank, select('DISTINCT ON (songs.rank, songs.shared_id) songs.*').order('songs.rank desc')
  scope :group_shared_order_published, select('DISTINCT ON (songs.published_at, songs.shared_id) songs.*').order('songs.published_at desc')
  scope :select_with_info, select('songs.*, posts.url as post_url, posts.content as post_content, blogs.name as blog_name, blogs.slug as blog_slug')
  scope :individual, select_with_info.with_blog_and_post.working
  scope :playlist_order_rank, group_shared_order_rank.select_with_info.with_blog_and_post.working
  scope :playlist_order_published, group_shared_order_published.select_with_info.with_blog_and_post.working

  acts_as_url :full_name, :url_attribute => :slug

  before_create  :get_real_url, :clean_url
  after_create :delayed_scan_and_save
  before_save :set_rank

  # Whitelist mass-assignment attributes
  attr_accessible :url, :link_text, :blog_id, :post_id, :published_at, :created_at

  def to_param
    slug
  end

  def reposted?
    shared_count > 0
  end

  def to_playlist
    { id: id, artist:artist_name, name:name, url:url, image:resolve_image(:small) }
  end

  def resolve_image(*type)
    type = type[0] || :original
    image? ? image(type) : post.image(type)
  end

  def full_name
    "#{artist_name} - #{name}"
  end

  def original_artists
    artists.where("authors.role = 'original'").joins(:authors)
  end

  # Ranking algorithm
  def set_rank
    plays = Math.log([listens.count,2].max)
    favs  = Math.log([broadcasts.count,2].max*100)
    time  = ((created_at || Time.now) - Time.new(2012))/100000
    self.rank = plays + favs + time
  end

  def check_if_working
    if !url.nil?
      begin
        uri  = URI.parse url
        req  = Net::HTTP.new(uri.host,uri.port)
        head = req.request_head(uri.path)

        if head.code == '200' and head.content_type =~ /audio|download/
          logger.info "Working"
          self.working = true
        else
          logger.info "Not working, #{head.code} | #{head.content_type}"
          self.working = false
        end
        self.save
      rescue => exception
        # error opening file
        logger.info "Error opening file"
      end
    end
    self.working
  end

  def delayed_check_if_working
    delay(:priority => 4).check_if_working
  end

  # Read ID3 Tag and generally collect information on the song
  def scan_and_save
    if !url.nil?
      begin
        total = nil
        prev  = 0
        logger.info "Scanning #{url} ..."

        open(url,
          :content_length_proc => lambda { |content_length|
            raise "Too Big" if (content_length > (1048576 * 40)) # 20 MB maximum song size
            total = content_length
          },
          :progress_proc => lambda { |at|
            now = (at.fdiv(total)*100).round
            if now > (prev+9)
              logger.info "Downloading... #{now}%"
              prev = now
            end
        }) do |song|
          logger.info "Getting song information"
          file = TagLib::MPEG::File.new(song.path)

          # Properties
          props        = file.audio_properties
          self.bitrate = props.bitrate.to_i
          self.length  = props.length.to_f

          # Tag
          tag               = file.id3v2_tag
          self.name         = tag.title || link_info[0] || '(Not Found)'
          self.artist_name  = tag.artist || link_info[1] || '(Not Found)'
          self.album_name   = tag.album
          self.track_number = tag.track.to_i
          self.genre        = tag.genre
          self.image        = get_album_art(tag)

          # Working if we have name or artist name at least
          self.working = name != '(Not Found)' or artist_name != '(Not Found)'

          # Processed
          self.processed = true

          # Update info if we have processed this song
          if working?
            # Parse artists and determine if original song
            self.original_song = find_or_create_artists

            # Add to blog station, new station, artist and user stations
            add_to_stations

            # Determine if we already have this song
            find_similar_songs

            self.slug = full_name.to_url
            logger.info "Processed and working!"
          else
            logger.info "Processed (couldn't read information)"
          end

          # Save
          self.save!
        end
      rescue Exception => e
        # self.processed = false
        # self.working = false
        logger.error e.message + "\n" + e.backtrace.join("\n")
      end
    else
      logger.info "No URL!"
    end
  end

  def delayed_scan_and_save
    if Rails.application.config.delay_jobs
      delay(:priority => 1).scan_and_save
    else
      scan_and_save
    end
  end

  # Parse album art from ID3 tag
  def get_album_art(*args)
    if args.size.zero?
      tag = nil
      open(url) do |song|
        tag = TagLib::MPEG::File.new(song.path).id3v2_tag
      end
    else
      tag = args.first
    end

    begin
      # Save picture
      cover = tag.frame_list('APIC').first
      if cover
        # Save pictures
        filetype = cover.mime_type[/gif|png|jpg|jpeg/i]
        filename = "song_#{id}.#{filetype}"
        write_tempfile(filename, cover.picture)
      end
    rescue Exception => e
      logger.error e.message + "\n" + e.backtrace.join("\n")
    end
  end

  # Parse and save album art
  def save_album_art
    get_album_art
    self.save
  end

  # Write binary pictures
  def write_tempfile(filename, data)
    tmp = Paperclip::Tempfile.new(filename, Rails.root.join('tmp'))
    tmp.binmode
    tmp << data
  end

  # Rules for filesharing sites
  def get_real_url
    case url
    when /hulkshare\.com/
      page = Nokogiri::HTML(open(url))
      links = page.css('a.hoverf').each do |link|
        if link['href'] =~ /tracker\.hulkshare/
          absolute_url = link['href']
        end
      end
      false
    else
      absolute_url = url
    end
  end

  def add_to_stations
    if processed?
      add_to_blog_station
      add_to_artists_stations
    end
  end

  def add_to_artists_stations
    authors.each do |author|
      artist = Artist.find(author.artist_id)
      if artist and artist.station
        Broadcast.create(song_id:id,station_id:artist.station.id) unless artist.station.song_exists?(id)
      else
        logger.error "No artist or artist station"
      end
    end
  end

  def add_to_blog_station
    if blog and blog.station
      Broadcast.create(song_id:id,station_id:blog.station.id) unless blog.station.song_exists?(id)
    else
      logger.error "No Blog or Blog station"
    end
  end

  def find_similar_songs
    if name and artist_name
      containers  = /[\[\]\(\)\,\&\-\']/
      tags        = /( (rmx|remix|mix)|(feat|ft)(\.| )|(featuring|produced by) |(original|vip|radio|vip|extended) (edit|rip|mix))+/i
      percents    = /(% ?){2,10}/
      search_name = name.gsub(containers,'%').gsub(tags,'%').gsub(percents,'').strip
      found       = Song.where("artist_name ILIKE (?) and name ILIKE(?) and id != ?", artist_name, search_name, id).oldest.first
    end

    if found
      # Ok we found a song that already exists similar to this one
      # Set our shared ID first
      self.shared_id = found.id
      self.save

      if found.shared_id.nil?
        # This means this is the first "match", so lets update it
        found.shared_id = found.id
        found.shared_count = 2
        found.save
      else
        # Else we have more than one song already existing thats similar
        # So we need to update all similar songs' shared_counts+1
        existing_similar_songs = Song.where(shared_id:shared_id)
        existing_similar_songs.update_all(shared_count:existing_similar_songs.count)
      end
    else
      self.shared_id = id
    end
  end

  def similar_songs
    Song.where(shared_id:id)
  end

  def find_or_create_artists
    original_song = true
    parse_artists.each do |name,role|
      original_song = false if role == :remixer
      match = Artist.where("name ILIKE (?)", name).first
      match = Artist.create(name: name) unless match
      self.authors.find_or_create_by_artist_id_and_role(match.id, role)
    end
    original_song
  end

  def parse_artists
    name_artists = artists_in_name
    artist_artists = artists_in_artist
    name_artists | artist_artists
  end

  def artists_in_name
    # Strip unnecessary stuff and parse the song name
    strip = /(extended|vip|original|club) mix|(extended|vip|radio) edit|radio bootleg/i
    all_artists(name:name.gsub(strip,''))
  end

  def artists_in_artist
    # Now parse the artist field
    artist_artists = all_artists(artist:artist_name)
    !artist_artists.empty? ? artist_artists : [[artist_name, :original]]
  end

  def all_artists(title)
    artist  = title[:artist].nil? ? false : true
    string  = title[:artist] || title[:name]
    matched = []

    # Match their respective roles
    featured = /(featuring |ft(\.?| )|feat(\.?| )|f\.){1}/i
    remixer  = / remix| rmx| edit| bootleg| mix/i
    producer = /(produced|prod\.?) by/i
    #cover    = / cover/i

    # Find any non-original artists
    if string =~ /#{featured}|#{remixer}|#{producer}/i
      string.split(/\(|\)/).reject(&:blank?).collect(&:strip).each do |part|
        # Splits up "one, two, three & four"
        split = /([^,&]+)(& ?([^,&]+)|, ?([^,&]+))*/i

        part.scan(/#{featured}#{split}/).flatten.compact.collect(&:strip).each do |artist|
          matched.push [artist,:featured] unless artist =~ featured or artist =~ /&|,/
        end

        part.scan(/#{split}#{remixer}/).flatten.compact.collect(&:strip).each do |artist|
          matched.push [artist,:remixer] unless artist =~ remixer or artist =~ /&|,/
        end

        part.scan(/#{producer}#{split}/).flatten.compact.collect(&:strip).each do |artist|
          matched.push [artist,:producer] unless artist =~ producer or artist =~ /&|,/
        end
      end
    elsif artist
      # If artist, we can look for comma separated names
      string.split(/, |& |vs\.? /i).each do |artist|
        matched.push [artist, :original]
      end
    else
      # If name, we can look for a badly formatted mp3
      # Such as "artist - song" inside the name
      #matched.push [name.gsub(/-.*/,'').strip, :original]
    end

    matched
  end

  def link_info
    split = link_text.split(/\s*(-|—|–)\s*/)
    split.size >= 3 ? [split[0], split[2]] : [nil,nil]
  end

  def clean_url
    self.url = URI.escape(url)
  end
end
