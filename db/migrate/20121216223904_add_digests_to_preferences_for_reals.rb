class AddDigestsToPreferencesForReals < ActiveRecord::Migration
  def change
    add_column :preferences, :digests, :string, default: 'off'
    add_index :preferences, :digests
  end
end
