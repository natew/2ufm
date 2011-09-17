class AddFileToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :file_file_name, :string
    add_column :songs, :file_updated_at, :string
  end
end
