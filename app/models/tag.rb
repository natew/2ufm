class Tag < ActiveRecord::Base

  belongs_to :song
  belongs_to :user

  validates :name, presence: true
  validates :song_id, presence: true

  attr_accessible :name, :song_id, :source, :user_id

  acts_as_url :name, url_attribute: :slug, allow_duplicates: true, sync_url: true

  scope :common, -> { select('COUNT(*) as num, name, slug').group(:name, :slug).order('num desc') }

  def to_param
    slug
  end

  def get_title
    name
  end

end
