class AddBroadcastCountToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :user_broadcasts_count, :integer, :default => 0
  end

  def add
    # Updates every save
    Broadcast.all.each do |b|
      b.save
    end
  end
end
