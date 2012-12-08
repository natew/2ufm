class AddActiveToGenres < ActiveRecord::Migration
  def change
    add_column :genres, :active, :boolean, :default => false
  end
end
