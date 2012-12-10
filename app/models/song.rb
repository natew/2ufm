# encoding: UTF-8

require 'open-uri'
require 'net/http'
require 'taglib'
require 'tempfile'
require 'soundcloud'
require 'securerandom'

class Song < ActiveRecord::Base
  include AttachmentHelper

  SOURCES = %w[direct soundcloud hulkshare]

  # Regular expressions
  BASE = {
    genre: /trap|dubstep|dub|house|electro|d&b|big room/i,
  }

  RE = {
    featured: /(featuring |ft(\.| )|feat(\.| )|f\.|w\.|f\/|w\/)/i,
    remixer: /((re([ -])?)?(make|work|edit|fix|mix)|rmx|boot-?leg)/i,
    mashup_split: / \+ | x | vs\.? /i,
    producer: / (produced by|produced w\/|prod\.? by |prod\.? w\.?\/? |prod\. )/i,
    cover: / cover/i,
    split: /([^,&]+)(& ?([^,&]+)|, ?([^,&]+))*/i, # Splits "one, two & three"
    open: /[\(\[\{]/,
    close: /[\)\]\}]/,
    containers: /[\{\[\(\)\]\}]/i,
    and: /,| & | and /i,
    time: /(now|[0-9]{2}(th|st|nd|rd) ?(jan(uary)?|feb(uary)?|mar(ch)?|apr(il)?|may|jun(e)?|jul(y)?|aug(ust)?|sep(tember)?|oct(ober)?|nov(ember)?|dec(ember)?)?)/i,
    quote_chars: /[\'\"\*]/,
    remix_types: /(\'s.*|20[0-9]{2}|#{BASE[:genre]}|summer|fall|spring|winter|bootleg|extended|vip|original|club|vocal|radio|vocal|instrumental|official|unofficial|remix|bootleg)/i
  }

  REMOVE = {
    featured: /.* #{RE[:featured]}/i,
    remixer: /(#{RE[:remix_types]} )+/i,
    all: /(([\*\[\(\/\{]| )*((exclusive )?(free |320)?(soundcloud ?|facebook ?)?(out #{RE[:time]}|dwnld ?|download ?|d\/?l ?)(free |320)*((on |or |link in )*(description ?|soundcloud ?|facebook ?)|320)*([\*\]\)\/\}]| )*)+)$/i,
    quotes: /^#{RE[:quote_chars]}+|#{RE[:quote_chars]}+$/i
  }

  SPLITS = {
    featured: /#{RE[:featured]}#{RE[:split]}/i,
    producer: /#{RE[:producer]}#{RE[:split]}/i,
    remixer: /#{RE[:split]}#{RE[:remixer]}/i,
    cover: /#{RE[:split]}#{RE[:cover]}/i,
    mashup: /#{RE[:mashup_split]}/i
  }

  STRIP = {
    remixer: /| (#{BASE[:genre]}|extended|official|original|vocal|instrumental|)? /i,
    producer: /^by /i
  }

  PREFIX = {
    # featured: /( |\(|\[|\{)/
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
  has_many   :shares
  has_many   :tags
  has_many   :song_genres
  has_many   :genres, :through => :song_genres

  before_create :set_source, :get_real_url, :clean_url, :set_token
  after_create :delayed_scan_and_save, :set_rank

  # Whitelist mass-assignment attributes
  attr_accessible :url, :link_text, :blog_id, :post_id, :published_at, :created_at, :artist_name, :name

  # acts_as_commentable

  # Attachments
  has_attachment :image, styles: { large: ['800x800#'], medium: ['256x256#'], small: ['128x128#'], icon: ['64x64#'], tiny: ['32x32#'] }
  has_attachment :waveform, styles: { original: ['1000x200'], small: ['250x50>'] }, filename: ":id_:style.png"
  has_attachment :file, :s3 => Yetting.s3_enabled, filename: ":id_:style.mp3"
  has_attachment :compressed_file, filename: ":token.mp3"

  # Validations
  validates :url, :presence => true
  validate  :unique_to_blog, :on => :create

  # Conditions
  scope :not_processed, where(processed: false)
  scope :processed, where(processed: true)
  scope :working, where(working: true)
  scope :not_working, where(working: true)
  scope :not_uploaded, where('songs.file_file_name is NULL')
  scope :unranked, where('songs.rank is NULL')
  scope :ranked, where('songs.rank is NOT NULL')
  scope :newest, order('songs.published_at desc')
  scope :oldest, order('songs.published_at asc')
  scope :recently, where('songs.created_at > ?', (Rails.env.development? ? 10.months.ago : 2.months.ago))
  scope :soundcloud, where(source: 'soundcloud')
  scope :youtube, where(source: 'youtube')
  scope :not_youtube, where('songs.source != ?', 'youtube')
  scope :time_limited, where('songs.seconds < ?', 600)
  scope :matching_id, where('songs.matching_id = songs.id')
  scope :min_broadcasts, lambda { |min| where('songs.user_broadcasts_count >= ?', min) }
  scope :within, lambda { |within| where('songs.created_at >= ?', within.ago) }
  scope :before, lambda { |before| where('songs.created_at < ?', before.ago) }
  scope :random, order('random() desc')

  # Categories
  scope :original, where(category: 'original')
  scope :remix, where(category: 'remix')
  scope :cover, where(category: 'cover')
  scope :mashup, where(category: 'mashup')

  # Joins
  scope :join_author_and_role, lambda { |id, role| joins(:authors).where(authors: {artist_id: id, role: role}) }
  scope :join_role, lambda { |role| joins(:authors).where(authors: {role: role}) }
  scope :with_authors, joins(:authors)
  scope :with_blog_station, joins('INNER JOIN "stations" on "stations"."blog_id" = "songs"."blog_id" INNER JOIN blogs on blogs.id = posts.blog_id')
  scope :with_post, joins(:post)
  scope :with_blog_station_and_post, with_blog_station.with_post
  scope :with_sender, joins('INNER JOIN users as sender ON sender.id = shares.sender_id')
  scope :with_receiver, joins('INNER JOIN users as receiver ON receiver.id = shares.receiver_id')

  # Data to select
  scope :select_post, select('posts.id as post_id, posts.url as post_url, posts.excerpt as post_excerpt')
  scope :select_info, lambda { select('stations.title as station_title, stations.slug as station_slug, stations.id as station_id, stations.follows_count as station_follows_count, blogs.url as blog_url').select_post }
  scope :select_distinct, lambda { |distinct| select("DISTINCT ON (#{distinct}, songs.matching_id) songs.*").select_info }
  scope :select_with_info, select('songs.*').select_info
  scope :user_broadcasted, select('broadcasts.created_at as published_at')

  # Orders
  scope :order_broadcasted, order('broadcasts.created_at desc')
  scope :order_rank, order('songs.rank desc')
  scope :order_user_broadcasts, order('songs.user_broadcasts_count desc')
  scope :order_published, order('songs.published_at desc')
  scope :order_published_asc, order('songs.published_at asc')
  scope :order_shared, order('shares.created_at desc')
  scope :order_random, order('random() desc')

  # Selects
  scope :select_sender, select('sender.username as sender_username, sender.station_slug as sender_station_slug, shares.created_at as sent_at')
  scope :select_receiver, select('receiver.username as receiver_username, receiver.station_slug as receiver_station_slug, shares.created_at as sent_at')
  scope :select_broadcasted_at, select('broadcasts.created_at as broadcasted_at')

  # Combination
  scope :with_conditions, not_youtube.working.processed.time_limited
  scope :for_playlist, with_conditions.with_blog_station_and_post
  scope :with_info_for_playlist_matching_id_distinct, lambda { |on| select_distinct(on).for_playlist.matching_id }
  scope :with_info_for_playlist_matching_id, select_with_info.for_playlist.matching_id
  scope :with_info_for_playlist, select_with_info.for_playlist
  scope :joins_user_broadcasts, select('songs.id').with_conditions.matching_id.joins(:broadcasts).order('broadcasts.created_at desc').where('broadcasts.parent = ?', 'user')

  # Playlists
  scope :playlist_rank, order_rank.with_info_for_playlist_matching_id_distinct('songs.rank')
  scope :playlist_newest, order_published.with_info_for_playlist_matching_id_distinct('songs.published_at')
  scope :playlist_oldest, order_published_asc.with_info_for_playlist_matching_id_distinct('songs.published_at')
  scope :playlist_popular_week, within(7.days).order_user_broadcasts.with_info_for_playlist_matching_id
  scope :playlist_popular_month, within(30.days).order_user_broadcasts.with_info_for_playlist_matching_id
  scope :playlist_popular_year, within(365.days).order_user_broadcasts.with_info_for_playlist_matching_id
  scope :playlist_trending, min_broadcasts(2).order_rank.with_info_for_playlist_matching_id_distinct('songs.rank')
  scope :playlist_received, select_sender.with_sender.order_shared.with_info_for_playlist_matching_id
  scope :playlist_sent, select_receiver.with_receiver.order_shared.with_info_for_playlist_matching_id
  scope :playlist_shuffle, order_random.with_info_for_playlist_matching_id
  scope :playlist_broadcasted, select_broadcasted_at.order_broadcasted.with_info_for_playlist_matching_id
  # scope :playlist_recently_liked, select_with_info.with_blog_station_and_post.where(id: latest_user_broadcasts)

  # Scopes for pagination
  scope :limit_page, lambda { |page| offset((page.to_i - 1) * Yetting.per).limit(Yetting.per) }
  scope :limit_full, lambda { |page| limit(page * Yetting.per) }

  def to_param
    slug
  end

  def get_title
    full_name
  end

  def reposted?
    blog_broadcasts_count > 1
  end

  def self.playlist_most_listened(options)
    Song.with_info_for_playlist_matching_id.where(id:
      Song
        .not_youtube.working.processed.time_limited
        .select('songs.id, count(listens.id) as listens_count')
        .where('listens.created_at > ?', options[:within].ago)
        .joins(:listens)
        .group('songs.id')
        .order('listens_count desc')
        .limit(options[:limit])
        .map(&:id)
    )
  end

  def self.song_page(songs, song_id)
    return false if songs.length == 1
    sql = songs.to_sql
    order_by_index = sql.rindex(/(order by .*)/i)
    order_by = sql[order_by_index..-1]
    row_sql = songs.select("ROW_NUMBER() over(#{order_by}) AS rn").select('songs.id as my_id').to_sql
    row = Song.find_by_sql("SELECT rn, my_id FROM (#{row_sql}) x where x.my_id = #{song_id}")[0].rn.to_i
    logger.info row
    page = row / Yetting.per
    logger.info page
    songs.offset(page * Yetting.per).limit(Yetting.per)
  end

  def self.user_unread_received_songs(id)
    Share.where('shares.receiver_id = ? and shares.read = false', id).count
  end

  def self.by_tag(tag)
    Song.joins('inner join tags on tags.song_id = songs.id').where('tags.slug = ?', tag.slug)
  end

  def self.where_conditions(name)
    %Q{
      #{name}.processed = 't'
      AND #{name}.working = 't'
      AND #{name}.source != 'youtube'
      AND #{name}.seconds < 600
    }
  end

  def self.by_genre(genre, type, page)
    id = genre.id
    where_extra = genre.includes_remixes ? '' : "AND A.category NOT IN ('remix', 'mashup')"
    offset = (page.to_i - 1) * Yetting.per

    case type
    when 'trending'
      order = min_broadcasts(2).order_rank.to_sql.gsub(/WHERE /, 'AND')
    when 'latest'
      order = newest.to_sql
    when 'shuffle'
      order = random.to_sql
    end

    order.gsub!(/SELECT.*\"songs\"/, '')

    Song.find_by_sql(%Q{
      SELECT songs.*,
        blogs.url as blog_url,

        stations.title as station_title,
        stations.slug as station_slug,
        stations.id as station_id,
        stations.follows_count as station_follows_count,

        posts.url as post_url,
        posts.excerpt as post_excerpt
      FROM
      (
          SELECT distinct id,
          (
              SELECT
              COUNT(*) FROM
              song_genres b
              WHERE A.id = b.song_id
              AND b.source = 'artist'
              AND b.genre_id = '#{id}'
          ) as artist,
          (
              SELECT
              COUNT(*) FROM
              song_genres b
              WHERE A.id = b.song_id
              AND b.source = 'blog'
              AND b.genre_id = '#{id}'
          ) as blog,
          (
              SELECT
              COUNT(*) FROM
              song_genres b
              WHERE A.id = b.song_id
              AND b.source = 'post'
              AND b.genre_id = '#{id}'
          ) as post,
          (
              SELECT
              COUNT(*) FROM
              song_genres b
              WHERE A.id = b.song_id
              AND b.source = 'tag'
              AND b.genre_id = '#{id}'
          ) as tag
          FROM songs A
          WHERE #{where_conditions('A')}
          #{where_extra}
      ) AA
      INNER JOIN
        songs on AA.id = songs.id
      INNER JOIN
        posts on posts.id = songs.post_id
      INNER JOIN
        blogs on blogs.id = songs.blog_id
      INNER JOIN
        stations on stations.blog_id = blogs.id
      WHERE (AA.artist > 0 AND AA.blog > 0)
      OR (AA.artist > 0 AND AA.post > 0)
      OR (AA.tag > 0)
      AND songs.id = songs.matching_id
      #{order}
      LIMIT #{Yetting.per}
      OFFSET #{offset}
    })
  end

  def self.user_following_songs(type, id, offset, limit)
    where = ''
    case type
    when 'people'
      where = 'AND stations.user_id IS NOT NULL'
    when 'blogs'
      where = 'AND stations.blog_id IS NOT NULL'
    when 'artists'
      where = 'AND stations.artist_id IS NOT NULL'
    end

    join_where = where ? 'INNER JOIN stations ON stations.id = ff.station_id' : ''

    Song.find_by_sql(%Q{
      WITH a as (
          SELECT
            DISTINCT ON (maxcreated, broadcasts.song_id)
            broadcasts.song_id,
            broadcasts.station_id,
            MAX(broadcasts.created_at) AS maxcreated
          FROM broadcasts
          INNER JOIN follows ff ON ff.station_id = broadcasts.station_id
          #{join_where}
          INNER JOIN songs on songs.id = broadcasts.song_id
          WHERE ff.user_id = #{id}
            AND #{where_conditions('songs')}
          #{where}
          GROUP BY broadcasts.song_id, broadcasts.station_id
          ORDER BY maxcreated desc
          LIMIT #{limit}
          OFFSET #{offset}
        )
      SELECT
        a.maxcreated as broadcasted_at,
        s.*,
        blogs.url as blog_url,

        stations.title as following_station_title,
        stations.slug as following_station_slug,
        stations.id as following_station_id,
        stations.follows_count as following_station_follows_count,

        blog_stations.title as station_title,
        blog_stations.slug as station_slug,
        blog_stations.id as station_id,
        blog_stations.follows_count as station_follows_count,

        posts.url as post_url,
        posts.excerpt as post_excerpt
      FROM a
        INNER JOIN
          songs s ON a.song_id = s.id
        INNER JOIN
          posts on posts.id = s.post_id
        INNER JOIN
          blogs on blogs.id = posts.blog_id
        INNER JOIN
          stations as blog_stations on blog_stations.slug = blogs.station_slug
        INNER JOIN
          stations on stations.id = a.station_id
        ORDER BY a.maxcreated desc
    })
  end

  def to_playlist
    { id: matching_id, artist_name:artist_name, name:name, image:resolve_image(:small) }
  end

  def resolve_image(*type)
    return '/images/default.png' if Rails.env.development?
    type = type[0] || :original
    image(type).to_s =~ /default/ ? post.image(type) : image(type)
  end

  def full_name
    [artist_name, name].reject(&:blank?).join(' - ') || ''
  end

  def file_url
    (Yetting.s3_enabled and file.present?) ? file.url.gsub(/\?.*/,'') : (absolute_url || url)
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
    favs = [Math.log(user_broadcasts_count * 10), 0].max
    time = (created_at - Time.new(2012)) / 100000
    self.rank = favs + time
  end

  def set_file_size
    return false unless file.present?
    begin
      response = http.request_head(file.url)
      file_size = response['content-length']
      self.file_file_size = file_size unless file_size.nil?
    rescue Exception => e
      logger.error "Error getting image"
      logger.error e.message
      logger.error e.backtrace.join("\n")
    end
    file_file_size
  end

  def set_image_type
    return false unless image.present?
    begin
      response = http.request_head(image.url)
      image_type = response['content-type']
      self.image_content_type = image_type unless image_type.nil?
    rescue Exception => e
      logger.error "Error getting image"
      logger.error e.message
      logger.error e.backtrace.join("\n")
    end
    image_content_type
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

  def direct
    source == 'direct'
  end

  def scan_and_save
    if source == 'youtube'
      process(nil)
    elsif !url.nil?
      begin
        total = nil
        prev  = 0
        logger.info "Scanning #{file_url} ..."

        if soundcloud_id and updated_at < 2.minutes.ago
          get_real_url
        end

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
          self.file = song if direct
          self.compressed_file = compress_mp3(song.path)
          process(song)
          self.save
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

  # Read ID3 Tag and generally collect information on the song
  def process(file)
    if file
      logger.info "Getting song information -- #{file.path}"
      TagLib::MPEG::File.open(file.path) do |taglib|
        tag = taglib.id3v2_tag || taglib.id3v1_tag
        logger.info "Tag information -- #{tag.inspect}"
        break unless tag

        # Soundcloud info
        if source == 'soundcloud' and soundcloud_id
          client = Soundcloud.new(:client_id => Yetting.soundcloud_key)
          track = client.get("/tracks/#{soundcloud_id}")
          title = track.title
          genre = track.genres
          artist = track.user.username
          set_soundcloud_tags(track)
        end

        # Properties
        props = taglib.audio_properties
        if props
          self.bitrate = props.bitrate.to_i
          self.seconds = props.length.to_f
        else
          logger.error "No properties, no seconds or bitrate!?"
        end

        # Tag
        self.name         = title || tag.title || ''
        self.artist_name  = artist || tag.artist || ''
        self.album_name   = tag.album
        self.track_number = tag.track.to_i
        self.genre        = genre || tag.genre
        self.image        = get_album_art(tag)
      end

    elsif source == 'youtube'
      return unless get_youtube_info
    end

    set_original_tag
    clean_name

    # Working if we have name or artist name at least
    self.working = !name.blank? and !artist_name.blank?

    # Update info if we have processed this song
    if working? and !processed?

      # Generate waveform
      if file and waveform_file_name.nil?
        self.waveform = generate_waveform(file.path)
      end

      # fix_empty_soundcloud_tags(file.path)
      find_matching_songs
      delete_file_if_matching
      find_or_create_artists
      set_category
      add_to_stations

      # reset genres
      self.genres.destroy_all
      delayed_add_to_genres

      # Slug & Processed
      self.slug = full_name.to_url
      self.processed = true

      logger.info "Processed #{id} working!"
    else
      logger.info "Processed #{id} (no information)"
    end

    # Save
    self.save!
  end

  def delete_file_if_matching
    self.file.clear if matching_id != id
  end

  def split_artists_from_name
    return false unless name =~ / [-—]|[-—] /
    logger.info "Splitting... #{name}"
    split = name.split(/[-—]/)
    self.artist_name = split.shift.strip
    self.name = split.join('-').strip
    full_name
  end

  def get_file
    begin
      get_url = get_real_url || url
      logger.info "Getting #{get_url}"
      io = open(get_url, :content_length_proc => lambda { |content_length|
        raise "Too Big" if content_length > Yetting.file_size_limit
      })

      if io
        logger.info "Got file"
        self.file = io
      else
        nil
      end
    rescue Exception => e
      logger.error "Exception getting file: #{e.message}"
      logger.error e.backtrace.join("\n")
    end
  end

  def save_file
    get_file
    self.save
  end

  def delayed_save_file
    delay(:priority => 2).save_file
  end

  def compress_mp3(mp3_path=nil)
    mp3_path = open(file_url).path if !mp3_path
    compressed = Paperclip::Tempfile.new(["song_#{id}_compressed", ".mp3"], Rails.root.join('tmp'))
    ffmpeg_command = "ffmpeg -i \"#{mp3_path}\" -y -map_metadata 0 -acodec libmp3lame -ac 2 -ab #{Yetting.file_compression}k -ar 44100 \"#{compressed.path}\""
    logger.info ffmpeg_command
    output = `#{ffmpeg_command}`
    logger.info output
    logger.info "Compressed size: #{compressed.size}"
    if compressed.size > 0
      compressed
    else
      nil
    end
  end

  def set_compressed_file
    logger.info file.url
    open(file.url) do |file|
      self.compressed_file = compress_mp3(file.path)
      self.save
    end
  end

  def delayed_set_compressed_file
    delay.set_compressed_file
  end

  # Generate waveform
  def generate_waveform(mp3_path=nil)
    mp3_path = open(file_url).path if !mp3_path
    image_path = Paperclip::Tempfile.new('song_waveform_' + id.to_s + '.png', Rails.root.join('tmp'))

    tmp_wav_name = id.to_s + '.wav'
    tmp_wav = Tempfile.new(tmp_wav_name)
    ffmpeg_command = "ffmpeg -y -i \"#{mp3_path}\" -f wav \"#{tmp_wav.path}\" > /dev/null 2>&1"
    logger.info ffmpeg_command
    `#{ffmpeg_command}`

    if tmp_wav.size > 0
      Waveform.generate(tmp_wav.path, image_path,
        method: :rms,
        width: 1000,
        height: 200,
        background_color: :transparent,
        color: '#000000',
        force: true
      )
      image_path
    else
      nil
    end
  end

  def update_waveform
    self.waveform = generate_waveform(nil)
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
    tag = args.first
    if !tag
      open(file_url) do |song|
        tag = TagLib::MPEG::File.new(song.path).id3v2_tag
        logger.info tag
      end
    end

    begin
      # Save picture
      cover = tag.frame_list('APIC').first
      logger.info 'cover: ' + cover.to_s
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
    img = get_album_art
    if img
      self.image = img
      self.save
    end
  end

  # Write binary pictures
  def write_tempfile(filename, data)
    logger.info 'Tempfile: ' + filename
    logger.info 'Size:' + data.size.to_s
    tmp = Paperclip::Tempfile.new(filename, Rails.root.join('tmp'))
    tmp.binmode
    tmp << data
  end

  def get_youtube_info
    self.source = 'youtube' if url.match(/youtube\.com/)
    get_real_url if youtube_id.nil?
    return false unless youtube_id
    youtube_data = HTTParty.get("https://gdata.youtube.com/feeds/api/videos/#{youtube_id}?v=2&alt=json")
    return false unless youtube_data
    json = youtube_data.parsed_response
    return false unless json

    begin
      json = json['entry']
      self.name = Sanitize.clean(json['title']['$t']).truncate(250)
      return false unless split_artists_from_name
      self.description = Sanitize.clean(json['media$group']['media$description']['$t']).truncate(250)
      self.seconds = json['media$group']['media$content'][0]['duration']
    rescue
      logger.error "Error parsing YouTube API"
      return false
    end

    self
  end

  def set_source
    case url
    when /hulkshare\.com/
      self.source = 'hulkshare'
    when /soundcloud\.com/
      self.source = 'soundcloud'
    when /youtube\.com/
      self.source = 'youtube'
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
        client = Soundcloud.new(:client_id => Yetting.soundcloud_key)

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
          curl_redirect = `curl -I "#{track.stream_url}?client_id=#{Yetting.soundcloud_key}"`
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

    when 'youtube'
      video_id = url.match(/youtube.com.*(?:\/|v=)([^&$]+)/i)
      return unless video_id and video_id.length > 1
      video_id = video_id[1]
      self.youtube_id = video_id
    end

    # Return url
    absolute_url
  end

  def create_genres(genres, source)
    genres.each do |genre|
      SongGenre.find_or_create_by_song_id_and_genre_id_and_source(id, genre, source)
    end
  end

  def add_to_genres
    tag_genres = self.tags.select('genres.id').joins('inner join genres on genres.name ILIKE(tags.name)').map(&:id)
    artist_genres = self.artists.select('genres.id').joins(:genres).map(&:id)
    blog_genres = self.blog.genres.select('genres.id').map(&:id)
    post_content = self.post.content
    post_genres = Genre.active.to_a.keep_if { |g| post_content =~ /#{g.name}/i }.map(&:id)

    ActiveRecord::Base.transaction do
      create_genres(tag_genres, 'tag')
      create_genres(artist_genres, 'artist')
      create_genres(blog_genres, 'blog')
      create_genres(post_genres, 'post')
    end
  end

  def delayed_add_to_genres
    delay(priority: 4).add_to_genres
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
      ActionController::Base.new.expire_fragment("blog_artists_#{blog.id}")
    else
      logger.error "No Blog or Blog station"
    end
  end

  def to_searchable(string)
    logger.info string
    string.gsub!(/#{RE[:remix_types]} ?#{RE[:remixer]}?/i, '')
    # string.gsub!(/[\'\"][^']+[\'\"]/, '') # remove anything in quotes (too greedy?)
    string.gsub!(/[,\-\_\&]|#{RE[:containers]}|#{REMOVE[:all]}|#{RE[:producer]}|#{RE[:featured]}|#{RE[:mashup_split]}/i, '%')
    ('%' + string.strip).gsub(/(% ?){2,}/,'%').split('%').map(&:strip).join('%') + '%'
  end

  def searchable_name
    to_searchable("#{artist_name}%#{name}")
  end

  def find_matching_songs
    return unless working and match_name != '%'

    matching_songs = Song.working.oldest#.select("(artist_name || ' ' || name) as full_name")

    searchable_name.split('%').each do |name_part|
      matching_songs = matching_songs.where("(artist_name || ' ' || name) ILIKE(?)", "%#{name_part}%") unless name_part.empty?
    end

    matching_song = matching_songs.first

    if matching_song
      logger.info "Found matching song #{matching_song.id}"
      return false if matching_song.id == matching_id
      self.matching_id = matching_song.id
    else
      self.matching_id = id
      return false
    end

    # Update any join table info
    broadcasts.each do |broadcast|
      broadcast.update_attributes(song_id: matching_id) rescue ActiveRecord::RecordNotUnique
    end

    # Update counter caches
    last_broadcast = Broadcast.find_by_song_id(matching_id)
    last_broadcast.update_actions if last_broadcast


    shares.each do |share|
      share.update_attributes(song_id: matching_id) rescue ActiveRecord::RecordNotUnique
    end

    # Update existing matching songs
    existing_matching_songs = Song.where(matching_id: matching_id)
    count = existing_matching_songs.size + 1
    existing_matching_songs.update_all(matching_count: count)
    self.matching_count = count

    existing_matching_songs.map(&:id)
  end

  def update_matching_songs
    find_matching_songs
    delete_file_if_matching
    self.save
  end

  def delayed_update_matching_songs
    delay(priority: 4).update_matching_songs
  end

  def matching_songs
    Song.where(matching_id:id)
  end

  def similar_songs
    Song.where("name ILIKE(?) and id != ?", to_searchable(name), id) unless name.empty?
  end

  def fix_broadcasts
    if id != matching_id
      Broadcast.where('song_id = ?', id).each do |b|
        existing = Broadcast.where(song_id: matching_id, station_id: b.station_id)
        if existing
          b.destroy
        else
          b.update_attributes(song_id: matching_id)
        end
      end
    end
  end

  def find_or_create_artists
    if working?
      artists = parse_artists
      if !artists.empty?
        artists.each do |name, role|
          # Find or create artist
          match = Artist.where("name ILIKE (?)", name).first
          match = Artist.create(name: name) unless match

          # Find or create author
          self.authors.find_or_create_by_artist_id_and_role(match.id, role)
        end
      else
        # Not working if we don't have any artists
        self.working = false
      end
    end
  end

  def set_category
    artist_roles = parse_artists.flatten

    if artist_roles.include? :mashup
      self.category = 'mashup'
    elsif artist_roles.include? :cover
      self.category = 'cover'
    elsif artist_roles.include? :remixer
      self.category = 'remix'
    else
      self.category = 'original'
    end
  end

  def update_category
    set_category
    self.save
  end

  def delayed_update_category
    delay(priority: 4).update_category
  end

  def rescan_artists
    split_artists_from_name
    self.authors.destroy_all
    find_or_create_artists
    set_category
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
    logger.info "#{id}: #{full_name}"
    split_and_find_artists(name) | find_artists(artist_name) | split_and_find_artists(artist_name)
  end

  def find_artists(name)
    matches = []
    search_name = name.gsub(/#{RE[:open]}.*|#{RE[:featured]}.*|#{RE[:producer]}.*/i, '')

    if has_mashups(search_name)
      find_mashups(search_name) do |artist|
        matches.push [artist, :mashup]
      end
    else
      if search_name =~ RE[:and]
        clean_split(search_name, RE[:and]) do |artist|
          matches.push [artist.strip, :original]
        end
      else
        matches.push [search_name.strip, :original]
      end
    end
    matches.push [search_name.strip, :original] if matches.empty?
    matches.reject(&:blank?)
  end

  def split_and_find_artists(name)
    matches = []
    split_containers(name) do |part, is_in_container|
      if has_mashups(part)
        find_mashups(part) do |artist|
          artist.gsub!(RE[:remixer], '')
          matches.push [artist, :mashup]
        end
      else
        part = " " + part
        matches = matches + find_artists_types(part, is_in_container)
      end
    end
    matches.reject(&:blank?)
  end

  def split_containers(string)
    before_container = string.gsub(/#{RE[:open]}.*/, '').strip
    yield [before_container, false] unless before_container.empty?
    string[before_container.length..string.length].split(RE[:containers]).each do |part|
      yield [part, true]
    end
  end

  def clean_split(string, regex)
    string.split(regex).reject(&:blank?).collect(&:strip).each do |part|
      yield part
    end
  end

  def has_mashups(name)
    name.scan(/( vs\.? |#{RE[:mashup_split]})/i).empty? ? false : true
  end

  def find_mashups(name)
    clean_split(name, RE[:mashup_split]) do |artist|
      clean_split(artist, RE[:and]) do |split_artist|
        yield split_artist
      end
    end
  end

  def find_artists_types(part, container = false)
    return unless part
    matches = []
    types = [:producer, :featured]
    types = types + [:remixer, :cover] if container
    types.each do |type|
      scan_artists(part, type) do |match|
        matches.push match
      end
    end
    matches.reject(&:empty?)
  end

  def scan_artists(part, type)
    regex = RE[type]
    return unless part =~ regex
    part.gsub!(REMOVE[type], '') if REMOVE.has_key? type
    artist = part.gsub(regex, '').strip
    return if artist =~ /^[&,]/
    logger.info "PART #{artist}"
    artist.split(RE[:and]).each do |split|
      yield [split.strip, type]
    end
  end

  def fix_empty_soundcloud_tags_from_url
    return unless working?
    get_real_url
    open(file_url) do |song|
      TagLib::MPEG::File.open(song.path) do |taglib|
        set_id3_tags(taglib)
        self.file = song
        self.save
      end
    end
  end

  def fix_empty_soundcloud_tags(path)
    if source == 'soundcloud' and soundcloud_id
      TagLib::MPEG::File.open(path) do |taglib|
        set_id3_tags(taglib)
      end
    end
  end

  def get_soundcloud_info
    if source == 'soundcloud' and soundcloud_id
      client = Soundcloud.new(:client_id => Yetting.soundcloud_key)
      client.get("/tracks/#{soundcloud_id}")
    end
  end

  def set_soundcloud_tags(track)
    return unless track
    tags = track.tag_list
    return unless tags and tags.length > 0

    logger.info "#{id} - #{tags}"
    self.soundcloud_tags_updated_at = Time.now

    quoted_tag_regex = /\"([a-zA-Z0-9\-\_ ]+)\"/
    tags.scan(quoted_tag_regex).flatten.each do |quoted_tag|
      self.tags.build(name: quoted_tag.strip.downcase, source: 'soundcloud')
    end

    tags.gsub!(quoted_tag_regex, '')

    tags.split(' ').each do |tag|
      self.tags.build(name: tag.strip.downcase, source: 'soundcloud')
    end
  end

  def update_soundcloud_tags
    begin
      track = get_soundcloud_info
      if track
        set_soundcloud_tags(track)
        self.save
      end
    rescue Exception => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
    end
  end

  def set_id3_tags(taglib)
    tag = taglib.id3v2_tag
    tag.title = name
    tag.artist = artist_name
    tag.genre = genre
    taglib.save
    logger.info "Fixed tags #{full_name}"
  end

  def fix_tags
    logger.info "Fixing #{id}: #{full_name}"

    # Reset name
    clean_name

    # Update matching songs
    find_matching_songs
    delete_file_if_matching

    # Reset artists
    self.broadcasts.where(parent: 'artist').destroy_all
    self.authors.destroy_all
    find_or_create_artists
    set_category
    add_to_artists_stations
    delayed_add_to_genres

    self.save

  end

  def delayed_fix_tags
    delay(priority: 6).fix_tags
  end

  def clean_name
    split_artists_from_name
    self.name = name.gsub(REMOVE[:all], '').strip.gsub(REMOVE[:quotes],'')
  end

  def clean_url
    self.url = URI.escape(url)
  end

  def report_failure
    self.failures = (failures || 0).next
    # self.working = false if failures > 10
    self.save
  end

  def set_original_tag
    self.original_tag = full_name
  end

  def set_token
    while true
      self.token = SecureRandom.hex(16)
      break unless Song.find_by_token(token)
    end
  end

  def set_token_and_save
    set_token
    self.save
  end

  private

  def unique_to_blog
    if Song.where('url = ? and blog_id = ? and id != ?', url, blog_id, id).count > 0
      errors.add :url, "This song already exists"
    end
  end
end
