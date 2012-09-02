$stdout.sync = true

namespace :authors do
  task :reset => :environment do
    puts "Deleting authors"
    Author.destroy_all

    puts "Updating has_ conditions on artists"
    Artist.update_all(
      :has_mashups => false,
      :has_originals => false,
      :has_remixes => false,
      :has_productions => false,
      :has_features => false
    )

    puts "Updating song authors"
    Song.working.each do |song|
      print "."
      song.delay.rescan_artists
    end
  end
end