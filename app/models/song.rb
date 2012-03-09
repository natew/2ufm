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
  
  before_create  :get_real_url, :clean_url
  after_create :delayed_scan_and_save

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
        
        if head.code == '200' and head.content_type =~ /audio|download/
          puts "Working"
          self.working = true
        else
          puts "Not working, #{head.code} | #{head.content_type}"
          self.working = false
        end
        self.save
      rescue => exception
        # error opening file
        puts "Error opening file"
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
        puts "Scanning #{url} ..."
        
        open(url,
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
        }) do |song|
          Mp3Info.open(song.path) do |mp3|
            puts "Opened... #{mp3.tag.artist} - #{mp3.tag.title}"
            
            # Working
            self.processed = true
            
            # Read from ID3
            self.name = mp3.tag.title
            self.artist_name = mp3.tag.artist
            self.album_name = mp3.tag.album
            self.track_number = mp3.tag.tracknum.to_i
            self.genre = mp3.tag.genre
            self.bitrate = mp3.tag.bitrate.to_i
            self.length = mp3.tag.length.to_f

            # Like it says...
            get_album_art(mp3)
            
            if name and artist_name
              # Weve gotten enough info
              self.working = true
            else
              # If the ID3 doesnt work, try at least using link text
              self.working = parse_from_link
            end
            
            # Update info if we have processed this song
            if working?
              find_similar_songs
              self.slug = full_name.to_url
              puts "Processed and working!"
            else
              puts "Processed (couldn't read information)"
            end
            
            # Save processing
            self.save!
            puts "Saved!"
          end
        end
      rescue Exception => e
        puts e.message
        puts e.backtrace.join("\n")
        logger.error(e.message + "\n" + e.backtrace.join("\n"))
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

  def delayed_scan_and_save
    if Rails.application.config.delay_jobs
      delay(:priority => 1).scan_and_save
    else
      scan_and_save
    end
  end

  # Parse album art from ID3 tag
  def get_album_art(*mp3)
    if mp3.size.zero?
      open(url) do |song|
        mp3 = Mp3Info.open(song.path)
      end
    else
      mp3 = mp3.first
    end

    # Save picture
    picture = mp3.tag2.APIC || mp3.tag2.PIC
    picture = picture[0] if picture.is_a? Array
    if picture
      # Read picture
      text_encoding, mime_type, picture_type, picture_data = picture.unpack("c Z* c a*")
      file_type = mime_type[/gif|png|jpg|jpeg/i]
      puts "Text Encoding: #{text_encoding} Mime type: #{mime_type} Picture type: #{picture_type}"
      path = "#{Rails.root}/public/attachments/#{Rails.env}/song_images/tmp/apic_#{Process.pid}_song_#{id}.#{file_type.downcase}"

      # Handle JPEGs
      if mime_type[/png/i]
        self.image = write_picture(path, picture[14,picture.length])
      else
        self.image = write_picture(path, picture_data)
      end
    end
  end

  # Write binary pictures
  def write_picture(path, data)
    File.open(path, 'wb') do |f|
      f.write data
    end
  end
  
  # Rules for filesharing sites
  def get_real_url
    case url
    when /hulkshare\.com/
      page = Nokogiri::HTML(open(curl))
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
      add_to_new_station
      add_to_blog_station
      add_to_artists_stations
    end
  end
  
  def add_to_artists_stations
    authors.each do |author|
      artist = Artist.find(author.artist_id)
      artist.station.songs << self unless artist.station.song_exists?(id)
    end
  end
  
  def add_to_blog_station
    blog = Blog.find(blog_id)
    blog.station.songs << self unless blog.station.song_exists?(id)
  end
  
  def add_to_new_station
    ns = Station.new_station
    if !ns.song_exists?(id)
      ns.songs << self 
      ns.songs.delete(ns.songs.group_by_shared.last) if ns.songs.count > 50 # So it stays this long
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
      self.authors.find_or_create_by_artist_id_and_role(match.id, role)
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
    producer = /(produced|prod\.?) by/i
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
    self.url = URI.encode(url)
  end
end
