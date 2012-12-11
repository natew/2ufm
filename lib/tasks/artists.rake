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

  task :scan_genres, [:offset, :per] => [:environment] do |t, args|
    puts args
    offset = args[:offset] ? args[:offset].to_i : 0
    per = args[:per] ? args[:per].to_i : 80
    iterations = (Artist.all.count - offset) / per
    puts "Scanning artists starting at #{offset}, #{per} at a time"
    (0..iterations).each do |i|
      Artist.order('name asc').offset(i * per + offset).limit(per).each do |artist|
        puts "#{artist.name} (#{artist.id})"
        artist.genres.destroy_all
        artist.update_genres
      end
      sleep 60
    end
  end
end