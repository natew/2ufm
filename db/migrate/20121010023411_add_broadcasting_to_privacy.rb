class AddBroadcastingToPrivacy < ActiveRecord::Migration
  def change
    add_column :privacies, :broadcasting, :boolean, :default => true
  end
end
