class ChangeSongUrlToText < ActiveRecord::Migration
  def change
    change_column :songs, :url, :text
  end
end
