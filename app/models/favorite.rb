class Favorite < ActiveRecord::Base
  belongs_to :favorable
  belongs_to :user
  validates_presence_of :user_id, :favorable_id, :favorable_type
  
  before_save :associate_user
  
  protected
  
  def associate_user
    unless self.user_id
      self.user_id = current_user.id if user_signed_in?
      false
    end
  end
end
