namespace :songs do
  task :rescan => :environment do
    songs = Song.all
    songs.each do |song|
      song.scan
    end
  end
end