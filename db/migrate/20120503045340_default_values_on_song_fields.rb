class DefaultValuesOnSongFields < ActiveRecord::Migration
  def up
    change_column_default :songs, :name, ''
    change_column_default :songs, :artist_name, ''
  end
end
