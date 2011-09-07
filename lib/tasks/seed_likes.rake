namespace :db do
  task :seed_likes => :environment do
    # Randomly like songs
    songs = Song.where('processed = true')
    songs.each do |s|
      likes = 20 + rand(100)
      while likes > 0
        u = User.order('random()').first
        f = s.favorites.create(:user_id => u.id)
        f.created_at = (rand(25)+1).days.ago
        f.save
        
        likes -= 1
      end
    end
    
    # Randomly follow stations
    stations = Station.all
    stations.each do |s|
      likes = 10 + rand(30)
      while likes > 0
        u = User.order('random()').first
        f = s.favorites.create(:user_id => u.id)
        f.created_at = (rand(25)+1).days.ago
        f.save
        
        likes -= 1
      end
    end
  end
end