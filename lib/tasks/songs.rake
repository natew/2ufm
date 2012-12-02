STDOUT.sync = true

namespace :songs do
  task :move_to_mp3 => :environment do
    Song.working.each do |song|
      id = song.id
      Thread.new(id) do |id|
        puts "Moving #{id}"
        `s3cmd mv s3://media.2u.fm/song_files/#{id}_original. s3://media.2u.fm/song_files/#{id}_original.mp3`
      end
    end
  end

  task :fix_soundcloud_tags => :environment do
    Song.working.soundcloud.each do |song|
      song.set_original_tag
      song.fix_artists
    end
  end

  task :fix_broadcasts => :environment do
    Broadcast.all.each do |broadcast|
      print "."
      broadcast.delay.update_counter_cache
    end
  end

  task :clear_cache => :environment do
    Rails.cache.clear
  end

  task :fix_files => :environment do
    Song.all.each do |song|
      song.upload_if_not_working
    end
  end

  task :upload_files => :environment do
    Song.working.not_uploaded.each do |song|
      song.delayed_get_file
    end
  end

  task :reset => :environment do
    songs = Song.update_all(processed:false)
  end

  task :processed => :environment do
    puts Song.where(processed:true).count
  end

  task :fix_similar_count => :environment do
    Song.all.each do |song|
      #song.shared_count = Song.where(matching_id:id).count
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

  task :add_to_stations => :environment do
    Song.all.each do |song|
      song.add_to_stations
    end
  end

  namespace :update do
    task :ranks => :environment do
      Song.working.each do |song|
        song.save
      end
    end

    task :matching => :environment do
      Song.working.each do |song|
        song.delayed_update_matching_songs
      end
    end

    task :waveforms => :environment do
      Song.working.each do |song|
        song.delayed_update_waveform
      end
    end

    task :artists_and_titles => :environment do
      Song.working.each do |song|
        song.rescan_artists
        song.set_linked_title
        song.save
      end
    end
  end

  namespace :scan do
    task :soundcloud_tags => :environment do
      Song.working.soundcloud.where('soundcloud_tags_updated_at IS NULL').each do |song|
        song.update_soundcloud_tags
      end
    end

    task :artists => :environment do
      Song.all.each do |song|
        song.delayed_rescan_artists
      end
    end

    task :similar => :environment do
      songs = Song.processed
      songs.each do |song|
        puts "Scanning #{song.name} (#{song.id})..."
        song.matching_id = nil
        song.find_similar_songs
        puts " == Similar to #{Song.find(song.matching_id).name}!" if song.matching_id
        song.save
      end
    end

    task :all => :environment do
      Song.working.each do |song|
        song.delayed_scan_and_save
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