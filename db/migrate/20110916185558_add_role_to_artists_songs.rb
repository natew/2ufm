class AddRoleToArtistsSongs < ActiveRecord::Migration
  def change
    add_column :artists_songs, :role, :string, :default => ''
  end
end
