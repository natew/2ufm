class AddProcessedToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :processed, :boolean, :default => false
  end
end
