class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title, :author, :url
      t.text :content
      t.references :blog
      t.boolean :songs_saved

      t.timestamps
    end
  end
end
