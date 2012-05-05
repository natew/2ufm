class Listen < ActiveRecord::Base
  belongs_to :song
  belongs_to :user

  validates :url, :presence => true
  validates :song_id, :presence => true
  validates :user_id, :presence => true

  default_scope order('listens.created_at desc')

  before_validation :anonymous_user, :on => :create
  before_create :gen_shortcode

  def has_user?
    user_id == 0 ? false : true
  end

  private

  def anonymous_user
    self.user_id = 0 if user_id.blank?
  end

  def gen_shortcode
    while true
      self.shortcode = (0..5).map{ ('A'..'Z').to_a.concat((0..9).to_a)[rand(35)] }.join
      break unless Listen.find_by_shortcode(shortcode)
    end
  end
end
