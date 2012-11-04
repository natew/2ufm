class AddFileKeyAgain < ActiveRecord::Migration
  def up
    add_column :songs, :file_key, :string
  end

  def down
    remove_column :songs, :file_key
  end
end
