class AddPopularityToSongs < ActiveRecord::Migration
  def change
  	add_column :songs, :rank, :float
  end
end
