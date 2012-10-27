class CreateAds < ActiveRecord::Migration
  def change
    create_table :ads do |t|
      t.string :name, :type, :location, :network
      t.integer :width, :height
      t.text :code
      t.timestamp :starts_at, :ends_at
      t.boolean :active

      t.timestamps
    end
  end
end
