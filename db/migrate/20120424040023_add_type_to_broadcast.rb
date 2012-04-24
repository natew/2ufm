class AddTypeToBroadcast < ActiveRecord::Migration
  def change
    add_column :broadcasts, :parent, :string
  end
end
