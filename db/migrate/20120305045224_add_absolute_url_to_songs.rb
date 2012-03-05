class AddAbsoluteUrlToSongs < ActiveRecord::Migration
  def change
  	add_column :songs, :absolute_url, :string
  end
end
