class AddPaperclipToArtists < ActiveRecord::Migration
  def change
    add_column :artists, :image_file_name, :string
    add_column :artists, :image_updated_at, :string
  end
end
