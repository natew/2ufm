namespace :songs do
  task :reset => :environment do
    songs = Song.update_all(processed:false)
  end

  task :processed => :environment do
    puts Song.where(processed:true).count
  end

  task :save => :environment do
    begin
      Song.where(working:true).each do |song|
        puts "Saving song #{song.id}"
        song.save
        puts "  rank = #{song.rank}"
      end
    rescue Exception => e
      puts e.message
    end
  end

  task :fix_similar_count => :environment do
    Song.all.each do |song|
      #song.shared_count = Song.where(shared_id:id).count
      song.save
    end
  end

  task :check_if_working => :environment do
    songs = Song.where('created_at > ?',31.days.ago)
    songs.each do |song|
      puts "Checking song #{song.name}..."
      working = song.delayed_check_if_working
    end
  end

  namespace :update do
    task :rank => :environment do
      Song.working.each do |song|
        song.set_rank
        song.save
      end
    end
  end

  namespace :scan do
    task :artists => :environment do
      Song.all.each do |song|
        song.delay.find_or_create_artists
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