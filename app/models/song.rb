require 'open-uri'
require 'net/http'
require 'mp3info'

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
  
  # Attachments
  has_attachment :image, styles: { original: ['300x300#'], medium: ['128x128#'], small: ['64x64#'] }
  has_attachment :file

  # Scopes
  scope :with_blog_and_post, joins(:blog, :post)
  scope :working, where(processed: true,working: true)
  scope :newest, order('songs.published_at desc')
  scope :oldest, order('songs.published_at asc')
  scope :group_by_shared, select('DISTINCT ON (broadcasts.created_at,songs.shared_id) songs.*').order('broadcasts.created_at desc, songs.shared_id desc')
  scope :select_with_info, select('songs.*, posts.url as post_url, posts.content as post_content, blogs.name as blog_name, blogs.slug as blog_slug')
  scope :individual, select_with_info.with_blog_and_post.working
  scope :playlist_ready, group_by_shared.select_with_info.with_blog_and_post.working
  
  acts_as_url :full_name, :url_attribute => :slug
  
  before_save  :clean_url
  after_create :scan_and_save

  def to_param
    slug
  end
  
  def reposted?
    shared_count > 0
  end
  
  def to_playlist
    { id: id, artist:artist_name, name:name, url:url }
  end
  
  def resolve_image(*type)
    type = type[0] || :original
    image? ? image(type) : post.image(type)
  end
  
  def full_name
    "#{artist_name} - #{name}"
  end
  
  def check_if_working
    if !url.nil?
      begin
        uri  = URI.parse url
        req  = Net::HTTP.new(uri.host,uri.port)
        head = req.request_head(uri.path)
        
        if head.code == '200' and head.content_type =~ /audio/
          self.working = true
          self.save
        end
      rescue => exception
        # error opening file
        puts "error opening file"
      end
    end
  end
  
  def delayed_check_if_working
    delay.check_if_working
  end
  
  def scan_and_save
    if !url.nil?      
      begin
        total = nil
        prev  = 0
        curl  = get_real_url
        puts "Scanning #{curl} ..."
        
        open(URI.parse(URI.encode(curl)),
          :content_length_proc => lambda { |content_length|
            raise "Too Big" if content_length > (1048576 * 40) # 20 MB maximum song size
            total = content_length
          },
          :progress_proc => lambda { |at|
            now = (at.fdiv(total)*100).round
            if now > (prev+9)
              puts "Downloading... #{now}%" 
              prev = now
            end
          }
        ) do |song|
          Mp3Info.open(song.path) do |mp3|
            puts "Opened... #{mp3.tag.artist} - #{mp3.tag.title}"
            
            # Working
            self.working = true
            
            # Read from ID3
            self.name = mp3.tag.title
            self.artist_name = mp3.tag.artist
            self.album_name = mp3.tag.album
            self.track_number = mp3.tag.tracknum.to_i
            self.genre = mp3.tag.genre
            self.bitrate = mp3.tag.bitrate.to_i
            self.length = mp3.tag.length.to_f
            
            # If the ID3 doenst help us
            if !name or !artist_name
              self.processed = parse_from_link
            else
              self.processed = true
            end
            
            puts "Processed... #{processed}"
            
            # Save picture
            picture = mp3.tag2.APIC || mp3.tag2.PIC
            picture = picture[0] if picture.is_a? Array
            if picture
              #picture.gsub(/\x00[PNG|JPG|JPEG|GIF]\x00\x00/,'')
              pic_type = picture.match(/PNG|JPG|JPEG|GIF/)
              puts "Picture found, #{pic_type}"
              if pic_type
                tmp_path = "#{Rails.root}/tmp/albumart/apic_#{Process.pid}_song#{id}.#{pic_type[0]}"
                File.open(tmp_path, 'wb') do |f|
                  logger.info("Song #{id}, Picture HEADER ===== #{picture[0,30]}")
                  f.write(picture[pic_type[0].length+3,picture.length])
                end
                self.image = File.new(tmp_path)
              end
            end
            
            # Update info if we have processed this song
            if processed?
              find_similar_songs
              self.slug = full_name.to_url
              puts "Processed successfully"
            end
            
            # Save processing
            self.save
            puts "Saved!"
            
            # Destroy tmp image!
            #
            #
            #
          end
        end
      rescue Exception => e
        puts "Error: '#{e.message}' please check logs for stacktrace"
        logger.info(e.message + "\n" + e.backtrace.inspect)
      end
      
      # Post-saving stuff
      if processed?
        find_or_create_artists
        add_to_stations
      end
    else
      puts "No URL!"
    end
  end
  handle_asynchronously :scan_and_save, :priority => 1
  
  # For processing SoundCloud, Hulkshare and the like
  def get_real_url
    curl = cleaned_url
    case curl
    when /hulkshare\.com/
      page = Nokogiri::HTML(open(curl))
      links = page.css('a.hoverf').each do |link|
        if link['href'] =~ /tracker\.hulkshare/
          return link['href']
        end
      end
      false
    else
      curl
    end
  end
  
  # Clean url
  def cleaned_url
    scrub_url(url)
  end
  
  def scrub_url(uri)
    clean = uri.gsub(/\/.*/) do |t|
      t.gsub(/[^.\/a-zA-Z0-9\-_ ]/) do |c|
        "%#{ c[0].ord<16 ? "0" : "" }#{ c[0].ord.to_s(16).upcase }"
      end.gsub(" ", "+")
    end
    clean.gsub(/\[/,'%5B').gsub(/\]/,'%5D')
  end
  
  def add_to_stations
    if processed?
      add_to_new_station
      add_to_blog_station
      add_to_artists_stations
    end
  end
  
  def add_to_artists_stations
    authors.each do |author|
      artist = Artist.find(author.artist_id)
      artist.station.songs << self
    end
  end
  
  def add_to_blog_station
    Blog.find(blog_id).station.songs << self
  end
  
  def add_to_new_station
    ns = Station.new_station
    if !ns.song_exists?(id)
      ns.songs << self
      ns.songs.delete(ns.songs.group_by_shared.last) if ns.songs.count > 50 # So it stays only 30 songs!
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
    parse_artists.each do |name,role|
      match = Artist.where("name ILIKE (?)", name).first
      match = Artist.create(name: name) unless match
      self.authors.create(artist: match, role: role)
    end
  end
      
  def parse_artists
    parse_from_link unless name and artist_name
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
    artist = title[:artist].nil? ? false : true
    string = title[:artist] || title[:name]
    matched = []

    # Match their respective roles
    featured = /(featuring|ft\.?|feat\.?|f\.){1}/i
    remixer  = / remix| rmx| edit| bootleg| mix/i
    producer = /produced by /i
    #cover    = / cover/i

    # Find any non-original artists
    if string =~ /#{featured}|#{remixer}|#{producer}/i
      string.split(/\(|\)/).reject(&:blank?).collect(&:strip).each do |part|        
        # Splits up "one, two, three & four"
        split = /([^,&]+)(& ?([^,&]+)|, ?([^,&]+))*/i

        part.scan(/#{featured}#{split}/).flatten.compact.each do |artist|
          matched.push [artist,:featured] unless artist =~ featured or artist =~ /&|,/
        end

        part.scan(/#{split}#{remixer}/).flatten.compact.each do |artist|
          matched.push [artist,:remixer] unless artist =~ remixer or artist =~ /&|,/
        end

        part.scan(/#{producer}#{split}/).flatten.compact.each do |artist|
          matched.push [artist,:producer] unless artist =~ producer or artist =~ /&|,/
        end
      end
    elsif artist
      # If artist, we can look for comma separated names
      string.split(/, |& |vs\.? /).each do |artist|
        matched.push [artist, :original]
      end
    else
      # If name, we can look for a badly formatted mp3
      # Such as "artist - song" inside the name
      #matched.push [name.gsub(/-.*/,'').strip, :original]
    end

    matched
  end
  
  private
  
  def parse_from_link
    split = link_text.split(/\s*-\s*/)
    if split.size == 2
      self.artist_name = split[0]
      self.name = split[1]
      true
    else
      false
    end
  end
  
  def clean_url
    self.url = URI.escape(url)
  end
end
