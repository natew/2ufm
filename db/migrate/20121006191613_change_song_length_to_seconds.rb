class ChangeSongLengthToSeconds < ActiveRecord::Migration
  def up
    rename_column :songs, :length, :seconds
  end
end
