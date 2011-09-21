class AddSharedCountToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :shared_count, :integer, :default => 0
  end
end
