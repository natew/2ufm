class CreateShares < ActiveRecord::Migration
  def change
    create_table :shares do |t|
      t.references :sender, :receiver
      t.integer :song_id
      t.string :song_name

      t.timestamps
    end
  end
end
