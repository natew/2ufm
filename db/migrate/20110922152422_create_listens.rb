class CreateListens < ActiveRecord::Migration
  def change
    create_table :listens do |t|
      t.string :shortcode, :url
      t.integer :time, :default => 0
      t.references :song
      t.timestamps
    end
  end
end
