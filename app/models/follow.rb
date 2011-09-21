class Follow < ActiveRecord::Base
  belongs_to :station, :counter_cache => true
  belongs_to :user
  
  validates :user_id, presence: true
  validates :station_id, presence: true
end
