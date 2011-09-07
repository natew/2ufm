namespace :db do
  task :seed_likes => :environment do
    # Randomly like songs
    songs = Song.all
    songs.each do |s|
      likes = 20 + rand(100)
      while likes > 0
        index = rand(10)
        u = User.find_by_id(index)
        
        if u
          f = s.favorites.create(:user_id => u.id)
          f.created_at = (rand(25)+1).days.ago
          f.save
        end
        
        likes -= 1
      end
    end
    
    # Randomly follow stations
    stations = Station.all
    stations.each do |s|
      likes = 10 + rand(30)
      while likes > 0
        index = rand(10)
        u = User.find_by_id(index)
        
        if u
          s = s.favorites.create(:user_id => u.id)
          s.created_at = (rand(25)+1).days.ago
          s.save
        end
        
        likes -= 1
      end
    end
  end
end