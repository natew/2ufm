class Share < ActiveRecord::Base
  belongs_to :sender, :class_name => "User"
  belongs_to :recevier, :class_name => "User"

  validates :song_id, :precence => true
  validates :song_name, :precense => true
end
