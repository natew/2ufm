class AddCompressedFileToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :compressed_file_file_name, :string
    add_column :songs, :compressed_file_file_size, :string
    add_column :songs, :compressed_file_updated_at, :string
  end
end
