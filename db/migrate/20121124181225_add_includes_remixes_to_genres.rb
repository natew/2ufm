class AddIncludesRemixesToGenres < ActiveRecord::Migration
  def change
    add_column :genres, :includes_remixes, :boolean, :default => false
  end
end
