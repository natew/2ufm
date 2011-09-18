class AddUrlsToArtists < ActiveRecord::Migration
  def change
    add_column :artists, :urls, :text
  end
end
