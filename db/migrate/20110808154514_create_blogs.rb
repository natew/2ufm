class CreateBlogs < ActiveRecord::Migration
  def change
    create_table :blogs do |t|
      t.string :name
      t.text :description, :feed
      t.string :url, :feed_url
      
      t.timestamp :feed_updated_at, :last_spidered
      t.timestamps
    end
  end
end
