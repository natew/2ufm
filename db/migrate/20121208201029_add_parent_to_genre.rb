class AddParentToGenre < ActiveRecord::Migration
  def change
    add_column :genres, :parent, :integer
  end
end
