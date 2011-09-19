namespace :songs do
  task :reset => :environment do
    songs = Song.update_all(processed: false)
  end
  
  task :processed => :environment do
    puts Song.where(processed:true).count
  end
  
  task :popular => :environment do
    already_popular  = Station.popular_station.songs.collect(&:shared_id)
    popular_song_ids =
      Broadcast.select('song_id, COUNT(song_id) as count_song_id').where('created_at > ? and song_id not in (?)', 2.days.ago, already_popular).group(:song_id).order(:count_song_id).limit(10).map(&:song_id)
    
    values = popular_song_ids.collect { |x| [Station.popular_station.id,x] }.map { |x| "(#{x[0]},#{x[1]})" }.join(',')
    ActiveRecord::Base.connection.execute("INSERT INTO broadcasts (station_id,song_id) VALUES #{values}")
  end
  
  namespace :scan do  
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