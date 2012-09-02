namespace :artists do
  task :discogs => :environment do
    Artist.all.each do |artist|
      artist.get_discogs_info
      artist.save
      sleep 1
    end
  end

  task :delete_empty => :environment do
    Artist.where('song_count = 0').destroy_all
  end
end