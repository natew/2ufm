class Share < ActiveRecord::Base
  belongs_to :sender, :class_name => "User"
  belongs_to :recevier, :class_name => "User"

  validates :song_id, presence: true
  validates :song_name, presence: true
end
