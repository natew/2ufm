class Broadcast < ActiveRecord::Base
  belongs_to :station
  belongs_to :song, :primary_key => :shared_id, :counter_cache => true
  
  validates :song_id, presence: true
  validates :station_id, presence: true
  
end
