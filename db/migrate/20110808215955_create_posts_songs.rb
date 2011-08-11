class CreatePostsSongs < ActiveRecord::Migration
  def change
    create_table :posts_songs, :id => false do |t|
      t.references :post, :song
    end
  end
end
