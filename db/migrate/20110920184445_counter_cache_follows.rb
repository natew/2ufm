class CounterCacheFollows < ActiveRecord::Migration
  def change
    add_index :follows, [:user_id, :station_id], :unique => true
    add_column :stations, :follows_count, :integer, :default => 0
  end
end
