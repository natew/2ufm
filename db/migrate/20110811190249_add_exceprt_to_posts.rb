class AddExceprtToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :excerpt, :text
  end
end
