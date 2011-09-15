class Broadcast < ActiveRecord::Base
  belongs_to :station
  belongs_to :song, :primary_key => :shared_id, :counter_cache => true
  
  default_scope order('created_at desc')
end
