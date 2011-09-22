class AddUserToListens < ActiveRecord::Migration
  def change
    add_column :listens, :user_id, :integer
  end
end
