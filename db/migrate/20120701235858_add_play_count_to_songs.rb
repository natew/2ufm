class AddPlayCountToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :play_count, :integer, :default => 0
  end
end
