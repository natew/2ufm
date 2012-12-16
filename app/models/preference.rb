class Preference < ActiveRecord::Base
  MAILINGS = %w[all follows shares friend_joins]
  DIGESTS = %w[none daily weekly monthly]

  belongs_to :user

  attr_accessible :mail_all, :mail_follows, :mail_shares, :mail_friend_joins, :digests

  validates :digests, inclusion: { in: DIGESTS }

  def self.digest_types
    DIGESTS
  end

  def unsubscribe(type)
    set_mailing(type, false)
  end

  def subscribe(type)
    set_mailing(type, true)
  end

  def set_mailing(type, val)
    if MAILINGS.include? type
      self['mail_' + type] = val
      self.save
    end
  end
end
