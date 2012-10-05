class AddOriginalTagsToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :original_tag, :string
  end
end
