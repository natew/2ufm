class ChangeTypeBecauseRails < ActiveRecord::Migration
  def change
    rename_column :ads, :type, :size
  end
end
