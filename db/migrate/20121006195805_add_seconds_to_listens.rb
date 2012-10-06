class AddSecondsToListens < ActiveRecord::Migration
  def change
    rename_column :listens, :time, :seconds
  end
end
