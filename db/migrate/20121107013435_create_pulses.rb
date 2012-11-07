class CreatePulses < ActiveRecord::Migration
  def change
    create_table :pulses do |t|
      t.string :action, :amount, :station_id, :song_id, :description
      t.timestamps
    end
  end
end
