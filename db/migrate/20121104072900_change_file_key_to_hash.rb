class ChangeFileKeyToHash < ActiveRecord::Migration
  def change
    rename_column :songs, :file_key, :hash
  end
end
