class Favorite < ActiveRecord::Base
  belongs_to :favorable, :polymorphic => true
  belongs_to :user
  
  validates_presence_of :user_id, :favorable_id, :favorable_type
  
  after_create :add_activity
  
  private
  
  def add_activity    
#    Activity.create({
#      :type => favorable_type,
#      :user_id => user_id,
#      :type_id => favorable_id
#    })
  end
end
