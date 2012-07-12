# encoding: UTF-8

require 'open-uri'
require 'net/http'
require 'taglib'
require 'tempfile'
require 'soundcloud'

class Song < ActiveRecord::Base
  include AttachmentHelper

  SOURCES = %w[direct soundcloud hulkshare]

  # Regular expressions
  RE = {
    :featured => /(featuring |ft\. ?|feat\. ?|f\. ?|w\/){1}/i,
    :remix => / remix| rmx| edit| bootleg| mix| remake| re-work| rework| extended remix/i,
    :mashup => / mashup| mash-up/i,
    :producer => /(produced by|prod\.?)/i,
    :cover => / cover/i,
    :split => /([^,&]+)(& ?([^,&]+)|, ?([^,&]+))*/i, # Splits "one, two & three"
    :open => /[\(\[\{]/,
    :close => /[\)\]\}]/,
    :containers => /[\(\)\[\]]|vs\.? |,| and | & | x /i,
    :percents => /(% ?){2,10}/
  }

  # Relationships
  belongs_to :blog
  belongs_to :post
  has_many   :broadcasts, :dependent => :destroy
  has_many   :stations, :through => :broadcasts
  has_many   :users, :through => :stations
  has_many   :authors
  has_many   :artists, :through => :authors
  has_many   :listens

  # Comments
  acts_as_commentable

  # Attachments
  has_attachment :image, styles: { large: ['800x800#'], medium: ['256x256#'], small: ['128x128#'], icon: ['64x64#'], tiny: ['32x32#'] }
  has_attachment :waveform, styles: { original: ['1000x200'], small: ['250x50>'] }
  has_attachment :file

  # Validations
  validates :url, :presence => true
  validate :unique_to_blog, :on => :create

  # Basic Scopes
  scope :unprocessed, where(processed: false)
  scope :processed, where(processed: true)
  scope :working, where(processed: true, working: true).where('soundcloud_id IS NULL')
  scope :newest, order('songs.created_at desc')
  scope :oldest, order('songs.published_at asc')

  # Basic types
  scope :with_authors, joins(:authors)
  scope :remixes, with_authors.where('"authors"."role" = \'remixer\'')
  scope :mashups, with_authors.where('"authors"."role" = \'mashup\'')
  scope :covers, with_authors.where('"authors"."role" = \'cover\'')
  scope :featuring, with_authors.where('"authors"."role" = \'featured\'')
  scope :productions, with_authors.where('"authors"."role" = \'producer\'')
  scope :originals, with_authors.where('"authors"."role" = \'original\'')

  # Joins
  scope :with_blog_station, joins('INNER JOIN "stations" on "stations"."blog_id" = "songs"."blog_id"')
  scope :with_post, joins(:post)
  scope :with_blog_station_and_post, with_blog_station.with_post

  # Data to select
  scope :select_with_info, select('posts.url as post_url, posts.excerpt as post_excerpt, stations.title as station_title, stations.slug as station_slug, stations.id as station_id, stations.follows_count as station_follows_count')
  scope :individual, select_with_info.with_blog_station_and_post.working
  scope :user, select_with_info.with_post.working

  # Orders
  scope :order_broadcasted_by_type, select('DISTINCT ON ("broadcasts"."created_at", "songs"."matching_id") songs.*').order('broadcasts.created_at desc')
  scope :order_broadcasted, select('DISTINCT ON ("broadcasts"."created_at", "songs"."matching_id") songs.*').order('broadcasts.created_at desc')
  scope :order_ranked, select('DISTINCT ON ("songs"."rank", "songs"."matching_id") songs.*').order('songs."rank" desc')
  scope :order_published, select('DISTINCT ON ("songs"."published_at", "songs"."matching_id") songs.*').order('songs.published_at desc')

  # Scopes for playlist
  scope :playlist_order_broadcasted_by_type, order_broadcasted_by_type.individual
  scope :playlist_order_broadcasted, order_broadcasted.individual
  scope :playlist_order_rank, order_ranked.individual
  scope :playlist_order_published, order_published.individual

  # Scopes for users
  scope :user_order_broadcasted, order_broadcasted.user
  scope :user_order_rank, order_ranked.user
  scope :user_order_published, order_published.user

  # Scopes for pagination
  scope :limit_page, lambda { |page| page(page).per(Yetting.per) }
  scope :limit_full, lambda { |page, per| limit(page * per) }

  before_create :set_source, :get_real_url, :clean_url
  after_create :delayed_scan_and_save
  before_save :set_rank

  # Whitelist mass-assignment attributes
  attr_accessible :url, :link_text, :blog_id, :post_id, :published_at, :created_at

  def to_param
    slug
  end

  def get_title
    full_name
  end

  def reposted?
    blog_broadcasts_count > 1
  end

  def self.popular
    playlist_order_rank
  end

  def self.newest
    playlist_order_published
  end

  def self.user_following_songs(id, offset, limit)
    Song.find_by_sql(%Q{
      WITH a as (
          SELECT bb.song_id, MAX(bb.created_at) AS maxcreated
          FROM follows aa
          INNER JOIN broadcasts bb ON aa.station_id = bb.station_id
          WHERE aa.user_id = #{id}
          GROUP BY bb.song_id
        )
      SELECT
        DISTINCT ON (a.maxcreated, s.id)
        a.maxcreated as broadcasted_at,
        s.*,
        posts.url as post_url,
        posts.excerpt as post_excerpt,
        stations.title as station_title,
        stations.slug as station_slug,
        stations.id as station_id,
        stations.follows_count as station_follows_count
      FROM a
        INNER JOIN
          songs s ON a.song_id = s.id
        INNER JOIN
          posts on posts.id = s.post_id
        INNER JOIN
          broadcasts on broadcasts.song_id = s.id
        INNER JOIN
          follows on follows.station_id = broadcasts.station_id
        INNER JOIN
          stations on stations.id = broadcasts.station_id
      WHERE s.processed = 't'
        AND s.working = 't'
        AND s.soundcloud_id IS NULL
      ORDER BY
        a.maxcreated DESC
      OFFSET #{offset}
      LIMIT #{limit}
    })
  end

  def to_playlist
    { id: matching_id, artist_name:artist_name, name:name, url:url, image:resolve_image(:small) }
  end

  def resolve_image(*type)
    type = type[0] || :original
    image(type).to_s =~ /default/ ? post.image(type) : image(type)
  end

  def full_name
    "#{artist_name} - #{name}"
  end

  def file_url
    absolute_url || url
  end

  def original_artists
    artists.where("authors.role = 'original'").joins(:authors)
  end

  def user_broadcasts
    broadcasts.where(:parent => 'user')
  end

  def blog_broadcasts
    broadcasts.where(:parent => 'blog')
  end

  # Ranking algorithm
  def set_rank
    shared_song = Song.find(matching_id || id)
    plays = Math.log([shared_song.listens.count, 1].max)
    favs  = Math.log([shared_song.user_broadcasts_count, 1].max * 10)
    time  = ((shared_song.created_at || Time.now) - Time.new(2012)) / 100000
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
        logger.info "Scanning #{file_url} ..."

        open(file_url,
          :content_length_proc => lambda { |content_length|
            raise "Too Big" if (content_length > (1048576 * 40)) # 40 MB maximum song size
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
          tag = file.id3v2_tag

          # Soundcloud info
          if source == 'soundcloud' and soundcloud_id
            client = Soundcloud.new(:client_id => soundcloud_key)
            track = client.get("/tracks/#{soundcloud_id}")
            tag.title = track.title || tag.title
            tag.genre = track.genres || tag.genre
            tag.artist ||= track.user
          end

          # Properties
          props        = file.audio_properties
          self.bitrate = props.bitrate.to_i
          self.length  = props.length.to_f

          # Tag
          self.name         = tag.title || link_info[0] || ''
          self.artist_name  = tag.artist || link_info[1] || ''
          self.album_name   = tag.album
          self.track_number = tag.track.to_i
          self.genre        = tag.genre
          self.image        = get_album_art(tag)

          # Working if we have name or artist name at least
          self.working = !name.blank? and !artist_name.blank?

          # Parse artists and determine if original song
          # Re-determines if its working or not
          find_or_create_artists

          # Update info if we have processed this song
          if working? and !processed?
            # Clean name
            set_match_name

            # Waveform
            if waveform_file_name.nil?
              logger.info "Generating waveform..."
              self.waveform = generate_waveform(song.path)
            end

            # Determine if we already have this song
            update_matching_songs

            # Add to artist and blog stations
            add_to_stations

            # Slug
            self.slug = full_name.to_url

            # Processed
            self.processed = true

            logger.info "Processed and working!"
          else
            logger.info "Processed (no information)"
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

  # Generate waveform
  def generate_waveform(path=nil)
    path = open(file_url).path if !path
    # Waveform
    waveform = Waveform.new(path)
    waveform_path = Paperclip::Tempfile.new('song_waveform_'+id.to_s+'.png', Rails.root.join('tmp'))
    waveform.generate(waveform_path,
      method: :rms,
      width: 1000,
      height: 200,
      background_color: :transparent,
      color: '#000000',
      force: true
    )
    waveform_path
  end

  def update_waveform
    self.waveform = generate_waveform
    self.save
  end

  def delayed_update_waveform
    if Rails.application.config.delay_jobs
      delay(:priority => 4).update_waveform
    else
      update_waveform
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
      logger.error "Could not process album art"
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

  def set_source
    case url
    when /hulkshare\.com/
      self.source = 'hulkshare'
    when /soundcloud\.com/
      self.source = 'soundcloud'
    end
  end

  # Rules for filesharing sites
  def get_real_url
    case source

    when 'hulkshare'
      page = Nokogiri::HTML(open(url))
      links = page.css('a.hoverf').each do |link|
        if link['href'] =~ /tracker\.hulkshare/
          self.absolute_url = link['href']
        end
      end

    when 'soundcloud'
      begin
        # init soundcloud
        client = Soundcloud.new(:client_id => soundcloud_key)

        # find track id
        begin
          track_id = url.scan(/tracks(%.*F|\/)([0-9]+)/)[0][1]
        rescue
          track_id = client.get('/resolve', :url => url).id
        end

        if track_id
          self.soundcloud_id = track_id

          # get track url
          logger.info "Found track ID #{track_id}"
          track = client.get('/tracks/' + track_id.to_s)
          curl_redirect = `curl -I "#{track.stream_url}?client_id=#{soundcloud_key}"`
          logger.info "Curl redirect headers\n #{curl_redirect}"
          final_url = curl_redirect.match(/Location: (.*)\r/)[1]

          # set url
          self.absolute_url = final_url
          logger.info "Got soundcloud url: #{self.absolute_url}"
        else
          logger.error "Could not get soundcloud track ID"
        end
      rescue Exception => e
        # soundcloud error
        logger.error "Soundcloud error"
        logger.error e.message
        logger.error e.backtrace.join("\n")
      end
    end

    # Return url
    absolute_url
  end

  def add_to_stations
    logger.info "Adding to stations"
    add_to_blog_station
    add_to_artists_stations
  end

  def add_to_artists_stations
    artists.each do |artist|
      artist.station.broadcasts.create(song_id:matching_id, created_at:published_at) if artist.station
    end
  end

  def add_to_blog_station
    if blog
      blog.station.broadcasts.create(song_id:matching_id, created_at:published_at) if blog.station
    else
      logger.error "No Blog or Blog station"
    end
  end

  def to_searchable(string)
    string.gsub(RE[:containers],'%').gsub(/#{RE[:remix]}|#{RE[:featured]}|#{RE[:mashup]}/i, '%').gsub(RE[:percents],'%').strip
  end

  def similar_songs
    Song.where("name ILIKE(?) and id != ?", to_searchable(name), id) if name
  end

  def find_matching_songs
    Song.where("artist_name ILIKE(?) and name ILIKE(?) and id != ?", to_searchable(artist_name), match_name, id) if name and artist_name
  end

  def update_matching_songs
    found = matching_songs.oldest.first

    if found
      # Ok we found a song that already exists similar to this one
      # Set our shared ID first
      self.matching_id = found.id

      if found.matching_id.nil?
        # This means this is the first time weve matched it, lets update the original
        found.matching_id = found.id
        found.matching_count = 2
        found.save
      else
        # Else we have more than one song already existing thats similar
        # So we need to update all similar songs' shared_counts+1
        existing_matching_songs = Song.where(matching_id:matching_id)
        existing_matching_songs.update_all(matching_count:existing_matching_songs.size)
      end
    else
      self.matching_id = id
      false
    end
  end

  def matching_songs
    Song.where(matching_id:id)
  end

  def find_or_create_artists
    if working?
      artists = parse_artists
      if !artists.empty?
        original = true
        artists.each do |name,role|
          original = [:remixer, :mashup, :cover].include? role

          # Find or create artist
          match = Artist.where("name ILIKE (?)", name).first
          match = Artist.create(name: name) unless match

          # Find or create author
          self.authors.find_or_create_by_artist_id_and_role(match.id, role)
        end

        # Set if its an original song
        self.original_song = original
      else
        # Not working if we don't have any artists
        self.working = false
      end
    end
  end

  def rescan_artists
    self.find_or_create_artists
    self.save
  end

  def delayed_rescan_artists
    if Rails.application.config.delay_jobs
      delay.rescan_artists
    else
      rescan_artists
    end
  end

  def parse_artists
    logger.info "Parsing artists in #{id}: #{full_name}"
    name_artists = artists_in_name
    artist_artists = artists_in_artist
    merged = name_artists | artist_artists
    merged ? merged : []
  end

  def artists_in_name
    parse_name = name
    parse_name = link_info[1] if name.blank?
    # Strip unnecessary stuff and parse the song name
    parse_name = parse_name.gsub(/(extended|vip|original|club)|(extended|vip|radio) edit/i, '')
    all_artists(name: parse_name)
  end

  def artists_in_artist
    # Now parse the artist field
    parse_artist_name = artist_name
    parse_artist_name = link_info[0] if parse_artist_name.blank?
    all_artists(artist:parse_artist_name)
  end

  def all_artists(title)
    logger.debug "All artists in #{title}"
    artist  = title[:artist].nil? ? false : true
    string  = title[:artist] || title[:name]
    matched = []

    # Detect parenthesis
    parens = true if string =~ /\(/i

    # Find any non-original artists
    #   gsub() Strip everything up until "(" if there exists one
    #   split() Split when multiple parenthesis groups exist
    if string =~ /#{RE[:featured]}|#{RE[:remix]}|#{RE[:producer]}|#{RE[:cover]}/i
      string.gsub(/.*(?=\()/,'').split(/\(|\)/).reject(&:blank?).collect(&:strip).each do |part|
        part.scan(/#{RE[:featured]}#{RE[:split]}/).flatten.compact.collect(&:strip).each do |artist|
          matched.push [artist,:featured] unless artist =~ RE[:featured] or artist =~ /&|,/
        end

        part.scan(/#{RE[:producer]}#{RE[:split]}/).flatten.compact.collect(&:strip).each do |artist|
          matched.push [artist,:producer] unless artist =~ RE[:producer] or artist =~ /&|,/
        end

        # We can only trust data within a parenthesis for suffix attributes
        # IE: "Song Title Artist Name Remix", we can't determine "Artist Name"
        # TODO: Discogs lookup for artist name in that case
        if parens
          part.scan(/#{RE[:split]}#{RE[:remix]}/).flatten.compact.collect(&:strip).each do |artist|
            artist = artist.gsub(/\'s.*/i,'') # Remove types of remixes eg: "Arists's Piano Remix"
            matched.push [artist, :remixer] unless artist =~ RE[:remix] or artist =~ /&|,/
          end

          part.scan(/#{RE[:split]}#{RE[:cover]}/).flatten.compact.collect(&:strip).each do |artist|
            matched.push [artist, :cover] unless artist =~ RE[:producer] or artist =~ /&|,/
          end

          part.scan(/#{RE[:split]}#{RE[:mashup]}/).flatten.compact.collect(&:strip).each do |artist|
            matched.push [artist, :mashup] unless artist =~ RE[:producer] or artist =~ /&|,/
          end
        end
      end
    end

    if artist
      # TODO: Split and scan discogs here to determine whether the & is part of the artist name or just separating multiple artists

      # If artist, we can look for comma separated names
      original = string.gsub(/#{RE[:featured]}.*|\(.*/i,'')

      # Mashups
      mashup = /vs\.? |\+ /i
      if !original.scan(RE[:mashup]).empty?
        vs_list = /, |& |#{RE[:mashup]}/i
        original.split(vs_list).each do |artist|
          matched.push [artist.strip, :mashup]
        end

      # Original artists
      else
        original.split(/, |& /).each do |artist|
          matched.push [artist.strip, :original]
        end
      end

      matched.push [original.strip, :original] if matched.empty?
    else
      # If name, we can look for a badly formatted mp3
      # Such as "artist - song" inside the name
      #matched.push [name.gsub(/-.*/,'').strip, :original]
    end

    matched
  end

  def link_info
    if link_text
      split = link_text.split(/\s*(-|—|–)\s*/)
      split.size >= 3 ? [split[0], split[2]] : [nil,nil]
    else
      ['','']
    end
  end

  def clean_url
    self.url = URI.escape(url)
  end

  def get_match_name
    to_searchable(name.gsub(/(#{RE[:open]})?(Original Mix|Radio Edit|#{RE[:producer]} .*)(#{RE[:close]})?/i, '')).strip
  end

  def set_match_name
    self.match_name = get_match_name
  end

  private

  def soundcloud_key
    '35ececaff5ccc122375738961cd6d1dc'
  end

  def unique_to_blog
    if Song.where('url = ? and blog_id = ? and id != ?', url, blog_id, id).count > 0
      errors.add :url, "This song already exists"
    end
  end
end
