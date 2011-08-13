class AddLinkTextToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :link_text, :string
  end
end
