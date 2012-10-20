class Share < ActiveRecord::Base
  belongs_to :sender, :class_name => "User"
  belongs_to :receiver, :class_name => "User"
  belongs_to :song

  scope :within_last_day, where('created_at >= ?', 1.day.ago)

  validates :song_id,
    presence: true,
    uniqueness: {
      scope: :receiver_id,
      message: 'already sent to {{user}}'
    }

  validate :is_sent_to_friend

  private

  def is_sent_to_friend
    # if !receiver.is_following?(sender)
    #   errors.add(:base, 'User must be following you')
    # end
  end
end
