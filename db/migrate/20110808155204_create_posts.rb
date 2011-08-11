class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title, :author, :url
      t.text :content
      t.references :blog
      t.boolean :songs_saved
      t.timestamp :songs_updated_at

      t.timestamps
    end
  end
end
