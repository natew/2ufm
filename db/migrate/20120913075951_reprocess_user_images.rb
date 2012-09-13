class ReprocessUserImages < ActiveRecord::Migration
  def up
    User.all.each do |user|
      user.avatar.reprocess!
    end
  end

  def down
  end
end
