class Genre < ActiveRecord::Base
  default_scope order('name')

  has_and_belongs_to_many :blogs
  has_and_belongs_to_many :users
  has_and_belongs_to_many :artists

  acts_as_url :name, :url_attribute => :slug

  validates :name, presence: true, uniqueness: true

  before_create :map_name

  attr_accessible :name, :blog_ids

  ALTERNATIVE_NAMES = {
    'drum and bass' => 'Drum & Bass',
    'electronic' => 'Electro',
    'r&b' => 'R&B'
  }

  def to_param
    slug
  end

  def get_title
    name
  end

  def map_name
    self.name = ALTERNATIVE_NAMES[name] if ALTERNATIVE_NAMES[name]
  end

  def self.map_name(name)
    ALTERNATIVE_NAMES[name] || name
  end
end
