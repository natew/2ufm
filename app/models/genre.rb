class Genre < ActiveRecord::Base
  default_scope order('name')

  has_and_belongs_to_many :stations

  acts_as_url :name, :url_attribute => :slug

  validates :name, :presence => true

  def to_param
    slug
  end
end
