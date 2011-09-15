class AddCreatedAtToBroadcasts < ActiveRecord::Migration
  def change
    add_column :broadcasts, :created_at, :timestamp
  end
end
