require 'open-uri'
require 'mp3info'

class Song < ActiveRecord::Base  
  belongs_to  :blog
  belongs_to  :post
  has_many    :broadcasts, :dependent => :destroy
  has_many    :stations, :through => :broadcasts
  has_and_belongs_to_many  :artists
  
  has_attached_file	:image,
  					:styles => {
  						:original => ['300x300#', :jpg],
  						:medium   => ['128x128#', :jpg],
  						:small    => ['64x64#', :jpg],
  					},
            :path           => ':id_:style.:extension',
            :default_url    => '/images/default_:style.jpg',
            :storage        => 's3',
            :s3_credentials => 'config/amazon_s3.yml',
            :bucket         => 'fm-song-images'
            
  scope :with_posts, includes(:post)
  scope :processed, where(processed: true)
  
  acts_as_url :full_name, :url_attribute => :slug
  
  validates_presence_of :post_id, :blog_id
  
  before_save  :clean_url
  after_create :delayed_scan_and_save, :add_to_stations
  
  def to_param
    slug
  end
  
  def full_name
    "#{artist_name} - #{name}"
  end
  
  def is_popular?
    favorites.where('created at > ?', 10.days.ago).count > 10
  end
  
  def primary_artist
    artists.first
  end
  
  def scan_and_save
    puts "Scanning #{url} ..."
    unless url.nil?
      begin
        total = nil
        prev  = 0
        
        open(URI.escape(url),
          :content_length_proc => lambda { |content_length|
            if content_length > (1048576 * 20) # 20 MB maximum song size
              puts "Too big!"
              raise TooBig
            end
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
            
            puts "Completed processing... #{processed}"
            
            # Save picture
            picture = mp3.tag2.APIC || mp3.tag2.PIC
            picture = picture[0] if picture.is_a? Array
            if picture
              picture.gsub(/\x00[PNG|JPG|JPEG|GIF]\x00\x00/,'')
              pic_type = picture.match(/PNG|JPG|JPEG|GIF/)
              if pic_type
                tmp_path = "#{Rails.root}/tmp/albumart/apic_#{Process.pid}.#{pic_type[0]}"
                File.open(tmp_path, 'wb') { |f| f.write(picture[13,picture.length]) }
                self.image = File.new(tmp_path)
              end
            end
            
            # Update info if we have processed this song
            if processed?
              puts "Processed successfully"
              find_similar_songs
              find_or_create_artists
              self.slug = full_name.to_url
            end
            
            # Done
            self.save
            puts "Saved!"
            
            # Destroy tmp image!
            #
            #
            #
          end
        end
      rescue Exception => e
        logger.info(e.message + "\n" + e.backtrace.inspect)
      end
    end
  end
  
  def delayed_scan_and_save
    delay.scan_and_save
  end
  
  def find_or_create_artists
    if search_artist
      search_artist.each do |artist|
        match = Artist.where("name ILIKE (?)", artist).first

        if match
          self.artists << match
        else
          self.artists.create(:name => artist)
        end
      end
    end
  end
  
  def add_to_stations
    add_to_new_station # The new songs station
    if self.blog and !self.blog.station.song_exists?(id)
      self.blog.station.songs<<self
    end
  end
  
  def matching_songs
    if name and artist_name
      Song.where("artist_name ILIKE (?) and name ILIKE(?) and songs.id != ?", artist_name, search_name, id).first
    else
      false
    end
  end
  
  def find_similar_songs
    most_similar   = matching_songs
    self.shared_id = most_similar ? most_similar.id : id
  end
  
  def search_name
    if name
      name.gsub(/[()']/,'%').gsub(/( mix| remix|feat |ft |original mix|radio edit|extended edit|extended version| RMX|vip mix|vip edit)*|/i,'').strip
    else
      false
    end
  end
  
  def search_artist
    if name and artist_name
      title   = []
      artists = []
      
      # Artists in song title
      before = /[\S\s]+(\(|featuring |ft(\. | )|feat(\. | )|f\. |produced by ){1}/i
      after  = /((dubstep|extended|vip|original|radio)?[\s]?( remix| rmx| edit| bootleg| mix| version| rip))?\).*/i
      split  = /, /
      
      if name.match(before)
        title  = name.gsub(before,'').gsub(after,'')
        title  = title =~ split ? title.split(split) : [title]
      end
      
      # Artists in artist
      feat    = /\(?[\s]?(featuring |ft. |ft |feat. |feat |f. )\)?/i
      
      if artist_name.match(feat)
        artists = artist_name.split(feat).reject { |n| n =~ feat }
        artists = artists =~ split ? artists.split(split) : artists
      end
    
      # Return union of both + artist_name
      if !artists.empty? or !title.empty?
        artists | title
      else
        [artist_name]
      end
    else
      false
    end
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
  
  def add_to_new_station
    ns = Station.new_station
    if !ns.song_exists?(id)
      ns.songs<<self
      ns.songs.last.destroy if ns.songs.count > 30 # So it stays only 30 songs!
    end
    
  end
end
