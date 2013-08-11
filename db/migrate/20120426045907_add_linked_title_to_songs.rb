class AddLinkedTitleToSongs < ActiveRecord::Migration
  def change
    add_column :songs, :linked_title, :text

    # Song.all.each do |s|
    #   s.save
    # end
  end
end
