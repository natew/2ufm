class Activity < ActiveRecord::Base
  belongs_to :user
  
  before_save :crop_description, :associate_user
  
  validates_presence_of :user
  
  def self.latest_unique(options = {})
    self.find_by_sql("
          SELECT DISTINCT ON (foo.user_id) *
          FROM (
            SELECT   pulses.*, users.login as user_login
            FROM     pulses, users
            WHERE    adult = false
              AND pulses.user_id = users.id
            ORDER BY pulses.created_at desc
            LIMIT    #{options[:limit]*10}
          ) foo
          LIMIT #{options[:limit]}"
        )
  end
  
  protected
  
  def associate_user
    unless self.user_id
      self.user_id = current_user.id if user_signed_in?
      false
    end
  end
  
  def crop_description
    self.description = self.description[0,225] unless self.description.nil?
  end
end
