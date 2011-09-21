class AddWorkingToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :working, :boolean, :default => false
  end
end
