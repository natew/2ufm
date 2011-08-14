class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.string :type, :description
      t.integer :reference, :polymorphic => true
      t.references :user
      t.timestamps
    end
  end
end
