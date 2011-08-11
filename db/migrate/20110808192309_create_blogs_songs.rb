class CreateBlogsSongs < ActiveRecord::Migration
  def change
    create_table :blogs_songs, :id => false do |t|
      t.references :blog, :song
    end
  end
end
