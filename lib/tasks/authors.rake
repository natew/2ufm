namespace :authors do
  task :reset => :environment do
    Author.destroy_all
    Artist.update_all(
      :has_mashups => false,
      :has_originals => false,
      :has_remixes => false,
      :has_productions => false,
      :has_features => false
    )
    Song.working.each do |song|
      song.rescan_artists
    end
  end
end