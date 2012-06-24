class AddRoleCheckToArtists < ActiveRecord::Migration
  def change
    add_column :artists, :has_remixes, :boolean, :default => false
    add_column :artists, :has_mashups, :boolean, :default => false
    add_column :artists, :has_covers, :boolean, :default => false
    add_column :artists, :has_originals, :boolean, :default => false
    add_column :artists, :has_productions, :boolean, :default => false
    add_column :artists, :has_features, :boolean, :default => false
  end
end
