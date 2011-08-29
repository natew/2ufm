class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.string :type, :description
      t.references :user, :station, :song
      t.timestamps
    end
  end
end
