namespace :db do
  task :seed_likes => :environment do
    # Randomly like songs
    songs = Song.all
    songs.each do |s|
      likes = rand(100)
      while likes > 0
        index = rand(10)
        u = User.find_by_id(index)
        s.favorites.create(:user_id => u.id) unless u.nil?
        likes -= 1
      end
    end
    
    # Randomly follow stations
    stations = Station.all
    stations.each do |s|
      likes = rand(30)
      while likes > 0
        index = rand(10)
        u = User.find_by_id(index)
        s.favorites.create(:user_id => u.id) unless u.nil?
        likes -= 1
      end
    end
  end
end