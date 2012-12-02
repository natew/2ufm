class AddIndexOnListensUrl < ActiveRecord::Migration
  def change
    add_index :listens, :url
  end
end
