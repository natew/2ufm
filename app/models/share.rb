class Share < ActiveRecord::Base
  belongs_to :sender, :class_name => "User"
  belongs_to :recevier, :class_name => "User"

  validates :song_id, presence: true, uniqueness: {scope: :receiver_id}
end
