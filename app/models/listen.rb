class Listen < ActiveRecord::Base
  belongs_to :song
  belongs_to :user

  validates :url, :presence => true
  validates :song_id, :presence => true
  validates :user_id, :presence => true

  default_scope order('listens.created_at desc')

  before_validation :anonymous_user, :on => :create
  before_create :gen_shortcode
  after_create :update_song_play_count

  def has_user?
    user_id == 0 ? false : true
  end

  private

  def anonymous_user
    self.user_id = 0 if user_id.blank?
  end

  def gen_shortcode
    length = 5
    tries = 0
    while true
      o = [('a'..'z'),('A'..'Z'),('0'..'9')].map{|i| i.to_a}.flatten
      self.shortcode = (0..length).map{ o[rand(o.length)]  }.join
      break unless Listen.find_by_shortcode(shortcode)
      tries += 1
      length += 1 if tries % 3 == 0 # try longer string every 3 tries, well get there eventually
    end
  end

  def update_song_play_count
    song.update_attribute(:play_count, song.play_count.next)
  end
end
