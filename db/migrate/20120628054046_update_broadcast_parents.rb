class UpdateBroadcastParents < ActiveRecord::Migration
  def up
    Broadcast.where("parent = 'user' OR parent IS NULL").each do |broadcast|
      broadcast.parent = 'user'
      broadcast.save
    end
  end

  def down
  end
end
