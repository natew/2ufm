namespace :artists do
  task :discogs => :environment do
    Artist.all.each do |artist|
      artist.get_info
    end
  end
end