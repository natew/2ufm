class Ad < ActiveRecord::Base
  TYPES_TO_SIZES = {
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

  attr_accessible :code, :height, :name, :type, :width, :location, :network, :active

  before_save :set_width_and_height

  def set_width_and_height
    if TYPES_TO_SIZES.has_key? type
      self.width = TYPES_TO_SIZES[type][0]
      self.height = TYPES_TO_SIZES[type][1]
    end
  end
end
