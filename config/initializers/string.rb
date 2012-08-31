class String
  def is_numeric?
    true if Float(self) rescue false
  end

  def clean_split(regex)
    self.split(regex).reject(&:blank?).collect(&:strip).each do |part|
      yield
    end
  end

  def before_split(regex)

  end

  def clean_scan(regex)
    self.scan(regex).flatten.compact.collect(&:strip).reject do |string|
      string =~ /#{regex}|&|,/
    end
  end
end