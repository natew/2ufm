class DeleteFavorites < ActiveRecord::Migration
  def change
    drop_table :favorites if self.table_exists?("favorites")
  end
  
  def self.table_exists?(name)
    ActiveRecord::Base.connection.tables.include?(name)
  end
end
