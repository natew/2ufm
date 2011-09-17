namespace :songs do
  task :popular => :environment do
    already_popular  = Station.popular_station.songs.collect(&:shared_id)
    popular_song_ids =
      Broadcast.select('song_id, COUNT(song_id) as count_song_id').where('created_at > ? and song_id not in (?)', 2.days.ago, already_popular).group(:song_id).order(:count_song_id).limit(10).map(&:song_id)
    
    values = popular_song_ids.collect { |x| [Station.popular_station.id,x] }.map { |x| "(#{x[0]},#{x[1]})" }.join(',')
    ActiveRecord::Base.connection.execute("INSERT INTO broadcasts (station_id,song_id) VALUES #{values}")
  end
end