class Follow < ActiveRecord::Base
  belongs_to :station, :counter_cache => true
  belongs_to :user

  scope :within_last_day, where('created_at >= ?', 1.day.ago)

  validates :user_id, presence: true
  validates :station_id, presence: true
end
