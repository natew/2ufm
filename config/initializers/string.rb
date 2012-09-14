class String
  def is_numeric?
    true if Float(self) rescue false
  end

  def clean_split(regex)
    self.split(regex).reject(&:blank?).collect(&:strip).each do |part|
      yield part
    end
  end

  def clean_scan(regex, reject)
    self.scan(regex).flatten.compact.reject(&:blank?).each do |string|
      yield string.strip unless string =~ reject or string =~ /^[&,]/
    end
  end
end