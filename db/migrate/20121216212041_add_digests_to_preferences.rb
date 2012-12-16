class AddDigestsToPreferences < ActiveRecord::Migration
  def change
    add_column :preferences, :mail_digests, :boolean, default: false
  end
end
