namespace :songs do
  task :reset => :environment do
    songs = Song.update_all(processed:false)
  end
  
  task :processed => :environment do
    puts Song.where(processed:true).count
  end
  
  task :popular => :environment do
    popular_station_id = Station.popular_station.id
    popular_songs = Broadcast.select('song_id, COUNT(song_id) as count_song_id').where('created_at > ?', 7.days.ago).group(:song_id).order(:count_song_id).limit(50)
    
    popular_songs.each do |broadcast|
      Broadcast.create(song_id: broadcast.song_id, station_id: popular_station_id)
    end
  end
  
  task :fix_similar_count => :environment do
    Song.all.each do |song|
      #song.shared_count = Song.where(shared_id:id).count
      song.save
    end
  end
  
  namespace :scan do  
    task :working => :environment do
      songs = Song.where('created_at > ?',31.days.ago)
      songs.each do |song|
        puts "Checking song #{song.name}..."
        working = song.delayed_check_if_working
      end
    end
    
    task :similar => :environment do
      songs = Song.processed
      songs.each do |song|
        puts "Scanning #{song.name} (#{song.id})..."
        song.shared_id = nil
        song.find_similar_songs
        puts " == Similar to #{Song.find(song.shared_id).name}!" if song.shared_id
        song.save
      end
    end
    
    task :unprocessed => :environment do
      songs = Song.where(processed: false)
      songs.each do |song|
        song.delayed_scan_and_save
      end
    end
    
    task :some => :environment do
      songs = Song.order('random()').limit(20)
      songs.each do |song|
        song.scan_and_save
      end
    end
  end
end