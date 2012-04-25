# encoding: UTF-8

require 'open-uri'
require 'net/http'
require 'taglib'
require 'tempfile'

class Song < ActiveRecord::Base
  include AttachmentHelper

  # Relationships
  belongs_to :blog
  belongs_to :post
  has_many   :broadcasts, :dependent => :destroy
  has_many   :stations, :through => :broadcasts
  has_many   :users, :through => :stations
  has_many   :authors
  has_many   :artists, :through => :authors
  has_many   :listens

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
  after_create :delayed_scan_and_save, :set_rank

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

  def user_broadcasts
    broadcasts.where(:parent => 'user')
  end

  # Ranking algorithm
  def set_rank
    plays = Math.log([listens.count,1].max)
    favs  = Math.log([user_broadcasts.count,1].max*10)
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

          # Parse artists and determine if original song
          # Re-determines if its working or not
          find_or_create_artists

          # Update info if we have processed this song
          if working?
            # Add to stations
            add_to_stations

            # Determine if we already have this song
            find_similar_songs

            self.slug = full_name.to_url
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
    begin
      artists.each do |artist|
        artist.station.broadcasts.create(song_id:id)
      end
    rescue ActiveRecord::RecordNotUnique => e
      logger.error 'Already broadcasted'
    end
  end

  def add_to_blog_station
    if blog
      begin
        blog.station.broadcasts.create(song_id:id)
      rescue ActiveRecord::RecordNotUnique
        logger.error 'Already broadcasted'
      end
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
    if working?
      artists = parse_artists
      if !artists.empty?
        original = true
        artists.each do |name,role|
          original = false if role == :remixer or role == :mashup
          match = Artist.where("name ILIKE (?)", name).first
          match = Artist.create(name: name) unless match
          self.authors.find_or_create_by_artist_id_and_role(match.id, role)
        end
        self.original_song = original
      else
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
    puts "Parsing #{id}: #{artist_name} - #{name}"
    name_artists = artists_in_name unless name.blank?
    artist_artists = artists_in_artist unless name.blank?
    merged = name_artists | artist_artists
    merged ? merged : []
  end

  def artists_in_name
    # Strip unnecessary stuff and parse the song name
    strip = /(extended|vip|original|club)|(extended|vip|radio) edit/i
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
    featured = /(featuring |ft\. ?|feat\. ?|f\. ?|w\/){1}/i
    remixer  = / remix| rmx| edit| bootleg| mix/i
    producer = /(produced|prod\.?) by/i
    cover    = / cover/i
    split    = /([^,&]+)(& ?([^,&]+)|, ?([^,&]+))*/i # Splits "one, two & three"

    # Detect parenthesis
    parens = true if string =~ /\(/i

    # Find any non-original artists
    #   gsub() Strip everything up until "(" if there exists one
    #   split() Split when multiple parenthesis groups exist
    if string =~ /#{featured}|#{remixer}|#{producer}|#{cover}/i
      string.gsub(/.*(?=\()/,'').split(/\(|\)/).reject(&:blank?).collect(&:strip).each do |part|
        part.scan(/#{featured}#{split}/).flatten.compact.collect(&:strip).each do |artist|
          matched.push [artist,:featured] unless artist =~ featured or artist =~ /&|,/
        end

        part.scan(/#{producer}#{split}/).flatten.compact.collect(&:strip).each do |artist|
          matched.push [artist,:producer] unless artist =~ producer or artist =~ /&|,/
        end

        # We can only trust data within a parenthesis for suffix attributes
        # IE: "Song Title Artist Name Remix", we can't determine "Artist Name"
        # TODO: Discogs lookup for artist name in that case
        if parens
          part.scan(/#{split}#{remixer}/).flatten.compact.collect(&:strip).each do |artist|
            artist = artist.gsub(/\'s.*/i,'') # Remove types of remixes eg: "Arists's Piano Remix"
            matched.push [artist,:remixer] unless artist =~ remixer or artist =~ /&|,/
          end

          part.scan(/#{split}#{cover}/).flatten.compact.collect(&:strip).each do |artist|
            matched.push [artist,:cover] unless artist =~ producer or artist =~ /&|,/
          end
        end
      end
    elsif artist
      # TODO: Split and scan discogs here to determine whether the & is part of the artist name or just separating multiple artists

      # If artist, we can look for comma separated names
      original = string.gsub(/#{featured}.*|\(.*/i,'')

      # Mashups
      mashup = /vs\.? |\+ /i
      if !original.scan(mashup).empty?
        vs_list = /, |& |#{mashup}/i
        original.split(vs_list).each do |artist|
          matched.push [artist.strip, :mashup]
        end

      # Original artists
      else
        original.split(/, |& /).each do |artist|
          matched.push [artist.strip, :original]
        end
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
