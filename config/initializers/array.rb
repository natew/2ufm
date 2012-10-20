class Array
  def to_playlist
    self.map do |s|
      if s.processed?
        {
          id: s.matching_id,
          artist_name: s.artist_name,
          name: s.name,
          image: s.resolve_image(:small),
          seconds: s.seconds
        }
      end
    end.compact.to_json
  end
end
