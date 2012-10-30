$stdout.sync = true

namespace :fix do
  task :cache => :environment do
    Rails.cache.clear
  end

  task :duplicate_stations => :environment do
    stations = Station.select("slug, count(slug) as quantity").group(:slug).having("count(slug) > 1")
    stations.each do |station|
      artist = Artist.where(id:station.artist_id)
    end
  end

  task :reset_artists => :environment do
    puts "Resetting artist stations"
    Station.where('stations.artist_id IS NOT NULL').destroy_all

    puts "Resetting artists"
    Artist.destroy_all

    puts "Resetting authors"
    Author.destroy_all

    puts "Resetting songs"
    Song.working.each do |song|
      print "."
      song.delay(:priority => 4).find_or_create_artists
      song.delay(:priority => 5).add_to_artists_stations
    end
  end
end