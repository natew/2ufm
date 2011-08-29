class Favorite < ActiveRecord::Base
  belongs_to :favorable
  belongs_to :user
  validates_presence_of :user_id, :favorable_id, :favorable_type
  
  after_create :add_activity
  
  private
  
  def add_activity
    if favorable_type == 'song'
      type =  'like_song'
      station = nil
      song = favorable_id
    else
      type = 'follow_station'
      song = nil
      station = favorable_id
    end
    
    Activity.create({ :type => type, :user_id => user_id, :song_id => song, :station_id => station })
  end
end
