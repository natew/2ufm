class AddPrimaryKeyToBroadcasts < ActiveRecord::Migration
  def change
    add_column :broadcasts, :id, :primary_key
  end
end
