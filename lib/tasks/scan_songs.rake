namespace :songs do
  task :reset => :environment do
    songs = Song.update_all(processed: false)
  end
  
  namespace :scan do  
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