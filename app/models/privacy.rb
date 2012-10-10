class Privacy < ActiveRecord::Base
  MAILINGS = %w[all follows shares friend_joins]

  belongs_to :user

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
