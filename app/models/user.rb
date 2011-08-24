class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :login, :email, :password, :password_confirmation, :remember_me
  
  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login
  
  has_one :station
  has_many :activities, :dependent => :destroy
  has_many :favorites
  has_attached_file	:avatar,
  					:styles => {
  						:original => ['300x300#', :jpg],
  						:medium   => ['128x128#', :jpg],
  						:small    => ['64x64#', :jpg],
  					},
            :path           => ':id_:style.:extension',
            :default_url    => '/images/user_default.jpg',
            :storage        => 's3',
            :s3_credentials => 'config/amazon_s3.yml',
            :bucket         => 'fm-user-images'
  
  acts_as_url :username, :url_attribute => :slug
  
  before_save :create_station
  
  def to_param
    slug
  end
  
  def has_favorite_song?(id)
    favorable(:type => :song, :id => id).length > 0
  end
  
  def has_favorite_station?(id)
    favorable(:type => :station, :id => id).length > 0
  end
  
  def has_favorite_blog?(id)
    favorable(:type => :blog, :id => id).length > 0
  end
  
  def favorable(opts={})
    # favorable_type
    type = opts[:type] ? opts[:type] : :song
    type = type.to_s.capitalize
  
    # add favorable_id to condition if id is provided
    con = ["user_id = ? AND favorable_type = ?", self.id, type]
    
    # append favorable id to the query if an :id is passed as an option into the
    # function, and then append that id as a string to the "con" Array
    if opts[:id]
      con[0] += " AND favorable_id = ?"
      con << opts[:id].to_s
    end
   
    # Return all Favorite objects matching the above conditions
    favs = Favorite.where(con)
    
    case opts[:delve]
    when nil, false, :false
      return favs
    when true, :true
      # get a list of all favorited object ids
      fav_ids = favs.collect{|f| f.favorable_id.to_s}
  
      if fav_ids.size > 0
        # turn the Capitalized favorable_type into an actual class Constant
        type_class = type.constantize
  
        # build a query that only selects
        query = []
        fav_ids.size.times do
          query << "id = ?"
        end
        type_conditions = [query.join(" AND ")] + fav_ids
  
        return type_class.where(type_conditions)
      else
        return []
      end
    end       
  end
  
  protected
  
  def create_station
    station = Station.new(:name => username, :user_id => id)
    self.station_id = station.id
  end
  
  # Devise override for logins
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
  end
  
  # Attempt to find a user by it's email. If a record is found, send new
   # password instructions to it. If not user is found, returns a new user
   # with an email not found error.
   def self.send_reset_password_instructions(attributes={})
     recoverable = find_recoverable_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
     recoverable.send_reset_password_instructions if recoverable.persisted?
     recoverable
   end 
  
   def self.find_recoverable_or_initialize_with_errors(required_attributes, attributes, error=:invalid)
     (case_insensitive_keys || []).each { |k| attributes[k].try(:downcase!) }
  
     attributes = attributes.slice(*required_attributes)
     attributes.delete_if { |key, value| value.blank? }
  
     if attributes.size == required_attributes.size
       if attributes.has_key?(:login)
          login = attributes.delete(:login)
          record = find_record(login)
       else  
         record = where(attributes).first
       end  
     end  
  
     unless record
       record = new
  
       required_attributes.each do |key|
         value = attributes[key]
         record.send("#{key}=", value)
         record.errors.add(key, value.present? ? error : :blank)
       end  
     end  
     record
   end
  
   def self.find_record(login)
     where(["username = :value OR email = :value", { :value => login }]).first
   end
end
