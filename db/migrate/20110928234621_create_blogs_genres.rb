class CreateBlogsGenres < ActiveRecord::Migration
  def change
    create_table :blogs_genres, :id => false do |t|
      t.references :blog, :genre
    end
  end
end
