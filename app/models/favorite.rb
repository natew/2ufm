class Favorite < ActiveRecord::Base
  belongs_to :favorable, :polymorphic => true
  belongs_to :user
  
  validates_presence_of :user_id, :favorable_id, :favorable_type
  
  after_create :add_activity, :check_popularity
  
  # Builds favorite from a type (default: song), id, and user_id
  def build_by_type(*args)
    type = args[:type] || 'song'
    
    if args[:id] and args[:user_id]
      favorite_object(type).find(args[:id]).favorites.build(:user_id => args[:user_id])
    else
      nil
    end
  end
  
  private
  
  def favorite_object(type)
    type.classify.constantize
  end
  
  def check_popularity
    if favorable_type == 'song'
      song = Song.find(favorable_id)
      Station.popular_songs.songs<<song if song.is_popular?
    end
  end
  
  def add_activity    
#    Activity.create({
#      :type => favorable_type,
#      :user_id => user_id,
#      :type_id => favorable_id
#    })
  end
end
