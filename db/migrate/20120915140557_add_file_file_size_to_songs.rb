class AddFileFileSizeToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :file_file_size, :string
  end
end
