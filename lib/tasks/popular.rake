namespace :songs do
  task :popular => :environment do
    songs = Song.most_favorited(:limit => 25)
    Station.find_by_slug('popular-songs').songs<<songs
  end
end