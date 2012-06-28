class BroadcastDefaultType < ActiveRecord::Migration
  def change
    change_column :broadcasts, :parent, :string, :default => 'user'
  end
end
