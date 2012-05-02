namespace :seed do
  task :similar_songs => :environment do
    b1 = Blog.create(url:'http://test.com', name:'Blog 1')
    b2 = Blog.create(url:'http://test2.com', name:'Blog 2')
    b3 = Blog.create(url:'http://test3.com', name:'Blog 3')

    # b1.songs.create(url: 'http://soundcloud.com/the-clothes-hangar/two-door-cinema-club-eat-that-up-its-good-for-you')
    # b2.songs.create(url: 'http://dl.soundowl.com/3bwd.mp3')
  end

  task :blogs_stations => :environment do
    add_songs_to_blogs
  end

  task :artists_stations => :environment do
    add_songs_to_artists
  end

  task :broadcasts => :environment do
    # Randomly broadcast songs
    stations = Station.select(:id).order('random()').where(blog_id:nil,artist_id:nil).limit(500).map(&:id)
    songs    = Song.select(:id).order('random()').working.limit(100).map(&:id)

    while !stations.empty?
      begin
        Broadcast.create(station_id: stations.pop, song_id: songs[rand(100)], created_at: Date.today - rand(9000).minutes)
      rescue
        # Because were kinda cheating, lets ignore the inevitable index crash and just keep going
      end
    end
  end

  task :reset_broadcasts => :environment do
    Broadcast.excluding_stations([Station.new_station.id]).destroy_all
    add_songs_to_blogs
    add_songs_to_artists
  end

  task :follows => :environment do
    # Randomly follow stations
    stations = Station.order('random()').limit(500).map(&:id)
    users    = User.order('random()').limit(500).map(&:id)

    while !users.empty?
      begin
        Follow.create(station_id: stations.pop, user_id: users.pop, created_at: Date.today - rand(1440).minutes)
      rescue
        # Because were kinda cheating, lets ignore the inevitable index crash and just keep going
      end
    end
  end

  task :users => :environment do
    # Create users
    i = 0
    while i < 200
      num = i + rand(10000) + 500
      User.create(username: "user#{num}", email: "email#{num}@email.com", password: 'password')
      i += 1
    end
  end
end

def add_songs_to_blogs
  Song.all.each do |s|
    blog = Blog.find(s.blog_id)
    begin
      blog.station.songs << s
    rescue
    end
  end
end

def add_songs_to_artists
  Author.all.each do |author|
    begin
      artist = Artist.find(author.artist_id)
      Broadcast.create(station_id: artist.station.id, song_id: author.song_id)
    rescue
    end
  end
end