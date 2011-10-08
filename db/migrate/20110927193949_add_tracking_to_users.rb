class AddTrackingToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_visited, :string
    add_column :users, :last_station, :integer
    add_column :users, :last_song, :integer
  end
end
