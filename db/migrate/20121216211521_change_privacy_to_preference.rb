class ChangePrivacyToPreference < ActiveRecord::Migration
  def change
    rename_table :privacies, :preferences
  end
end
