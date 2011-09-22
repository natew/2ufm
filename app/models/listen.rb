class Listen < ActiveRecord::Base
  belongs_to :song
  
  validates :url, :presence => true
  validates :song_id, :presence => true
  validates :user_id, :presence => true
  
  before_create :gen_shortcode
  
  private
  
  def gen_shortcode
    while true
      self.shortcode = (0...8).map{ ('A'..'Z').to_a.concat((0..9).to_a)[rand(35)] }.join
      break unless Listen.find_by_shortcode(shortcode)
    end
  end
end
