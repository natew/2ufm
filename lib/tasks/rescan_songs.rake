namespace :songs do
  task :rescan => :environment do
    songs = Song.all
    songs.each do |song|
      song.delayed_scan_and_save
    end
  end
end