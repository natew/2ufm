class AddSourceToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :source, :string, :default => 'direct'
    add_column :songs, :soundcloud_id, :integer
  end
end
