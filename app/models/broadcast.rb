class Broadcast < ActiveRecord::Base
  belongs_to :station
  belongs_to :song, :primary_key => :shared_id, :counter_cache => true

  validates :song_id, presence: true
  validates :station_id, presence: true

  scope :excluding_stations, lambda { |ids| where(['station_id NOT IN (?)', ids]) if ids.any? }
end
