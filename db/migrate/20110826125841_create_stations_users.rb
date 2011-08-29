class CreateStationsUsers < ActiveRecord::Migration
  def change
    create_table :stations_users, :id => false do |t|
      t.references :station, :user
    end
  end
end
