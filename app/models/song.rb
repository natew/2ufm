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
    :featured => /(featuring |ft\.? ?|feat\.? ?|f\. ?|w\/){1}/i,
    :remix => / remix| rmx| edit| bootleg| mix| remake| re-work| rework| extended remix| bootleg remix/i,
    :mashup => / x .* x | mashup| mash-up/i,
    :mashup_split => / x | vs\.? /i,
    :producer => /(produced by|prod\.?)/i,
    :cover => / cover/i,
    :split => /([^,&]+)(& ?([^,&]+)|, ?([^,&]+))*/i, # Splits "one, two & three"
    :open => /[\(\[\{]/,
    :close => /[\)\]\}]/,
    :containers => /[\(\)\[\]]|vs\.? |,| and | & | x /i,
    :percents => /(% ?){2,10}/,
    :remove => /(original mix|preview|radio edit)/i
  }

  SQL = {
    :stations => %Q{
        stations.title as station_title,
        stations.slug as station_slug,
        stations.id as station_id,
        stations.follows_count as station_follows_count,
      },
    :posts => %Q{
        posts.url as post_url,
        posts.excerpt as post_excerpt,
      },
    :listens => %Q{
        listens.id as listen_id
      }
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
  has_attachment :file, :s3 => Yetting.s3_enabled

  # Validations
  validates :url, :presence => true
  validate :unique_to_blog, :on => :create

  # Basic Scopes
  scope :unprocessed, where(processed: false)
  scope :processed, where(processed: true)
  scope :working, where(processed: true, working: true)
  scope :not_uploaded, where('songs.file_file_name is NULL')
  scope :unranked, where('songs.rank is NULL')
  scope :ranked, where('songs.rank is NOT NULL')
  scope :newest, order('songs.published_at desc')
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

  # User related
  scope :with_user, lambda { |user|
    select('listens.id as listen_id').joins("LEFT JOIN listens on listens.song_id = songs.id AND listens.user_id = #{user.id}") unless user.nil?
  }

  # Data to select
  scope :select_with_info, select('songs.*, posts.url as post_url, posts.excerpt as post_excerpt, stations.title as station_title, stations.slug as station_slug, stations.id as station_id, stations.follows_count as station_follows_count')
  scope :individual, select_with_info.with_blog_station_and_post

  # Orders
  scope :order_broadcasted_by_type, order('broadcasts.created_at desc')
  scope :order_broadcasted, order('broadcasts.created_at desc')
  scope :order_ranked, order('songs.rank desc')
  scope :order_published, order('songs.published_at desc')

  # Selects
  scope :select_songs, select('DISTINCT ON (songs.published_at, songs.matching_id) songs.*')
  scope :select_distinct_broadcasts, select('DISTINCT ON (songs.matching_id, broadcasts.created_at) songs.*')
  scope :select_distinct_rank, select('DISTINCT ON (songs.rank, songs.id) songs.*')

  # Scopes for playlist
  scope :playlist_scope_order_broadcasted_by_type, select_distinct_broadcasts.working.order_broadcasted_by_type.individual
  scope :playlist_scope_order_broadcasted, select_distinct_broadcasts.working.order_broadcasted.individual
  scope :playlist_scope_order_rank, select_distinct_rank.order_ranked.individual
  scope :playlist_scope_order_published, select_songs.order_published.individual

  # Grouped Scopes
  scope :limit_inner, limit(Yetting.per * 20)
  scope :grouped, where('matching_id is not null').select(:matching_id).working.limit_inner
  scope :grouped_order_published, grouped.group(:matching_id, :published_at).newest.working.limit_inner
  scope :grouped_order_rank, grouped.group(:matching_id, :rank).order('songs.rank desc').where('songs.user_broadcasts_count > 0').working.limit_inner

  # Scopes for pagination
  scope :limit_page, lambda { |page| page(page).per(Yetting.per) }
  scope :limit_full, lambda { |page, per| limit(page * per) }

  before_create :set_source, :get_real_url, :clean_url
  after_create :delayed_scan_and_save, :set_rank

  # Whitelist mass-assignment attributes
  attr_accessible :url, :link_text, :blog_id, :post_id, :published_at, :created_at, :artist_name, :name

  def to_param
    slug
  end

  def get_title
    full_name
  end

  def reposted?
    blog_broadcasts_count > 1
  end

  def self.playlist_order_broadcasted(user)
    playlist_scope_order_broadcasted.with_user(user)
  end

  def self.playlist_order_broadcasted_by_type(user)
    playlist_scope_order_broadcasted_by_type.with_user(user)
  end

  def self.playlist_order_published(user)
    Song.where(id: Song.grouped_order_published).playlist_scope_order_published.with_user(user)
  end

  def self.playlist_order_rank(user)
    Song.where(id: Song.grouped_order_rank).playlist_scope_order_rank.with_user(user)
  end

  def self.user_following_songs(id, offset, limit)
    Song.find_by_sql(%Q{
      WITH a as (
          SELECT
            broadcasts.song_id,
            broadcasts.station_id,
            MAX(broadcasts.created_at) AS maxcreated
          FROM broadcasts
          INNER JOIN follows ff ON ff.station_id = broadcasts.station_id
          WHERE ff.user_id = #{id}
          GROUP BY broadcasts.song_id, broadcasts.station_id
          ORDER BY maxcreated desc
        )
      SELECT
        DISTINCT ON (a.maxcreated, s.id)
        a.maxcreated as broadcasted_at,
        s.*,
        #{SQL[:stations]}
        #{SQL[:posts]}
        #{SQL[:listens]}
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
          stations on stations.id = a.station_id
        LEFT JOIN
          listens on listens.song_id = s.id
          AND listens.user_id = #{id}
      WHERE s.processed = 't'
        AND s.working = 't'
      ORDER BY
        a.maxcreated DESC
      LIMIT #{limit}
      OFFSET #{offset}
    })
  end

  def to_playlist
    { id: matching_id, artist_name:artist_name, name:name, image:resolve_image(:small) }
  end

  def resolve_image(*type)
    type = type[0] || :original
    image(type).to_s =~ /default/ ? post.image(type) : image(type)
  end

  def full_name
    "#{artist_name} - #{name}"
  end

  def file_url
    file.present? ? file.url : absolute_url || url
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
    find_id = matching_id || id
    shared_song = Song.find(find_id) if find_id
    favs_count = 1
    time_created = created_at
    if shared_song
      favs_count = shared_song.user_broadcasts_count
      time_created = shared_song.created_at
    end
    favs  = [Math.log(favs_count * 10), 0].max
    time  = (time_created - Time.new(2012)) / 100000
    self.rank = favs + time
  end

  def check_if_working
    if !file.nil?
      begin
        uri  = URI.parse file.url
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

  def upload_if_not_working
    if !check_if_working
      self.file.clear
      self.delayed_scan_and_save
    end
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
            raise "Too Big" if (content_length > Yetting.file_size_limit) # 40 MB maximum song size
            total = content_length
          },
          :progress_proc => lambda { |at|
            now = (at.fdiv(total)*100).round
            if now > (prev+9)
              logger.info "Downloading... #{now}%"
              prev = now
            end
        }) do |song|
          # Set file
          self.file = song if Yetting.s3_enabled

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

          # Detect if they dumped the artist in the name
          split_artists_from_name

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
            find_matching_songs

            # Delete file if we already have it
            delete_file_if_matching

            # Add to artist and blog stations
            add_to_stations

            # Slug
            self.slug = full_name.to_url

            # Processed
            self.processed = true

            logger.info "Processed #{id} working!"
          else
            logger.info "Processed #{id} (no information)"
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

  def delete_file_if_matching
    self.file.clear if matching_id != id
  end

  def split_artists_from_name
    if artist_name == '' and name =~ /-/
      logger.info "Splitting... #{name}"
      split = name.split('-')
      self.artist_name = split.shift.strip
      self.name = split.join('-').strip
    end
  end

  def get_file
    begin
      get_real_url
      io = open(file_url, :content_length_proc => lambda { |content_length|
        raise "Too Big" if content_length > Yetting.file_size_limit
      })

      if io
        self.file = io
        self.save
      end
    rescue Exception => e
      logger.error "Exception getting file: #{e.message}"
      logger.error e.backtrace.join("\n")
    end
  end

  def delayed_get_file
    delay(:priority => 2).get_file
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
    '%' + string.gsub(RE[:containers],'%').gsub(/#{RE[:remix]}|#{RE[:featured]}|#{RE[:mashup]}/i, '%').gsub(RE[:percents],'%').strip + '%'
  end

  def similar_songs
    Song.where("name ILIKE(?) and id != ?", to_searchable(name), id) if name
  end

  def find_matching_songs
    if working
      matching_song = Song.where("artist_name ILIKE(?) and name ILIKE(?)", to_searchable(artist_name), to_searchable(match_name)).oldest.first
      self.matching_id = matching_song ? matching_song.id : id
      return false unless matching_song
      # Update songs counts
      existing_matching_songs = Song.where(matching_id: matching_id)
      count = existing_matching_songs.size + 1
      existing_matching_songs.update_all(matching_count: count)
      self.matching_count = count
    end
  end

  def update_matching_songs
    find_matching_songs
    self.save
  end

  def delayed_update_matching_songs
    delay.update_matching_songs
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
    split_artists_from_name
    find_or_create_artists
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
    matches = 0

    # Find any non-original artists
    #   gsub() Strip everything up until "(" if there exists one
    #   split() Split when multiple parenthesis groups exist
    if string =~ /#{RE[:mashup_split]}|#{RE[:mashup]}|#{RE[:featured]}|#{RE[:remix]}|#{RE[:producer]}|#{RE[:cover]}/i
      string.gsub(/.*(?=\()/,'').split(/\(|\)/).reject(&:blank?).collect(&:strip).each do |part|
        part.scan(/#{RE[:featured]}#{RE[:split]}/).flatten.compact.collect(&:strip).each do |artist|
          matched.push [artist,:featured] unless artist =~ RE[:featured] or artist =~ /&|,/
          matches += 1
        end

        part.scan(/#{RE[:producer]}#{RE[:split]}/).flatten.compact.collect(&:strip).each do |artist|
          matched.push [artist,:producer] unless artist =~ RE[:producer] or artist =~ /&|,/
          matches += 1
        end

        # We can only trust data within a parenthesis for suffix attributes
        # IE: "Song Title Artist Name Remix", we can't determine "Artist Name"
        # TODO: Discogs lookup for artist name in that case
        if parens
          part.scan(/#{RE[:split]}#{RE[:remix]}/).flatten.compact.collect(&:strip).each do |artist|
            artist = artist.gsub(/\'s.*/i,'') # Remove types of remixes eg: "Arists's Piano Remix"
            matched.push [artist, :remixer] unless artist =~ RE[:remix] or artist =~ /&|,/
            matches += 1
          end

          part.scan(/#{RE[:split]}#{RE[:cover]}/).flatten.compact.collect(&:strip).each do |artist|
            matched.push [artist, :cover] unless artist =~ RE[:cover] or artist =~ /&|,/
            matches += 1
          end

          part.scan(/#{RE[:mashup]}/).flatten.compact.collect(&:strip).each do |artist|
            matched.push [artist, :mashup] unless artist =~ RE[:mashup]
            matches += 1
          end

          # Only look for mashups if nothing else is found
          if matches == 0
            part.split(/#{RE[:mashup_split]}/).each do |artist|
              matched.push [artist, :mashup]
              matches += 1
            end
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
    to_searchable(name.gsub(/(#{RE[:open]})?(#{RE[:remove]}|#{RE[:producer]} .*)(#{RE[:close]})?/i, '')).strip
  end

  def set_match_name
    self.match_name = get_match_name
  end

  def report_failure
    self.failures = (failures || 0).next
    self.working = false if failures > 10
    self.save
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
