class AddReadToShares < ActiveRecord::Migration
  def change
    add_column :shares, :read, :boolean, :default => false
  end
end
