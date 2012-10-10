class UpdateUsersPrivacies < ActiveRecord::Migration
  def up
    User.all.each do |user|
      user.make_privacy
    end
  end

  def down
  end
end
