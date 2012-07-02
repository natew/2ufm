module SongExtensions
  def to_playlist
    self.map do |s|
      {:id => s.id, :artist_name => s.artist_name, :name => s.name, :url => s.url, :image => image } if s.processed?
    end.compact.to_json
  end
end