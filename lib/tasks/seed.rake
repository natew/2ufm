namespace :db do
  namespace :seed do
    task :blogs_stations => :environment do
      Song.all.each do |s|
        blog = Blog.find(s.blog_id)
        begin
          blog.station.songs << s
        rescue
        end
      end
    end
    
    task :artists_stations => :environment do
      Author.all.each do |author|
        begin
          artist = Artist.find(author.artist_id)
          Broadcast.create(station_id: artist.station.id, song_id: author.song_id)
        rescue
        end
      end
    end
    
    task :broadcasts => :environment do
      # Randomly follow stations
      stations = Station.order('random()').limit(500).map(&:id)
      songs    = Song.order('random()').limit(500).map(&:id)

      while !songs.empty?
        begin
          Broadcast.create(station_id: stations.pop, song_id: songs.pop, created_at: Date.today - rand(1440).minutes)
        rescue
          # Because were kinda cheating, lets ignore the inevitable index crash and just keep going
        end
      end
    end
    
    task :follows => :environment do
      # Randomly follow stations
      stations = Station.order('random()').limit(500).map(&:id)
      users    = User.order('random()').limit(500).map(&:id)

      while !users.empty?
        begin
          Follow.create(station_id: stations.pop, song_id: songs.pop, created_at: Date.today - rand(1440).minutes)
        rescue
          # Because were kinda cheating, lets ignore the inevitable index crash and just keep going
        end
      end
    end
    
    task :users => :environment do
      # Create users
      i = 0
      while i < 500
        User.create(username: "user#{i}", email: "email#{i}@email.com", password: 'password')
        i += 1
      end
    end
  end
end