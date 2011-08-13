class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  
  has_one :station
  
  validates_length_of       :login,    :within => 3..120
  validates_length_of       :email,    :within => 6..200
  validates_format_of       :email,    :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid email"
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  
  acts_as_url :title, :url_attribute => :slug
  acts_as_voter
  
  def to_param
    slug
  end
end
