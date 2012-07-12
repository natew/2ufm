class AddMatchingSongs < ActiveRecord::Migration
  def change
    rename_column :songs, :shared_id, :matching_id
    rename_column :songs, :shared_count, :matching_count
  end
end
