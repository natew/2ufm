namespace :db do
  namespace :seed do
    task :likes => :environment do
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