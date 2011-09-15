class UpdateSongsChangeCount < ActiveRecord::Migration
  def change
    rename_column :songs, :stations_count, :broadcasts_count
  end
end
