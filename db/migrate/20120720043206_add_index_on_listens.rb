class AddIndexOnListens < ActiveRecord::Migration
  def up
    add_index :listens, [:user_id, :song_id]
  end

  def down
  end
end
