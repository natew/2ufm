module IntegersFromString
  def integers_from_string(string)
    result = []
    Digest::SHA1.hexdigest(string).each_char{|c| result.push(c) if c.is_numeric? }
    result.join
  end
end