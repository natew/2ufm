class ChangeSongsHashToToken < ActiveRecord::Migration
  def change
    rename_column :songs, :hash, :token
  end
end
