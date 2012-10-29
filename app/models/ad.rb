class Ad < ActiveRecord::Base
  SIZES_TO_UNITS = {
    'leaderboard'       => [728,90],
    'skyscraper'        => [120,600],
    'banner'            => [468,60],
    'wide_skyscraper'   => [160,600],
    'small_rectangle'   => [180,150],
    'small_square'      => [200,200],
    'square'            => [250,250],
    'medium_rectangle'  => [300,250],
    'large_rectangle'   => [336,280]
  }

  scope :active, where(active: true)

  attr_accessible :code, :height, :name, :size, :width, :location, :network, :active

  before_save :set_width_and_height

  def set_width_and_height
    if SIZES_TO_UNITS.has_key? size
      self.width = SIZES_TO_UNITS[size][0]
      self.height = SIZES_TO_UNITS[size][1]
    end
  end
end
