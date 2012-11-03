class Array
  def to_playlist
    self.map do |s|
      {
        id: s.matching_id,
        artist_name: s.artist_name,
        name: s.name,
        image: s.resolve_image(:small),
        seconds: s.seconds,
        sc_id: s.soundcloud_id || ''
      }
    end.compact.to_json
  end
end
