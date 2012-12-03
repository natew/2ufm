class ReallyAddIndexOnTags < ActiveRecord::Migration
  def change
    add_index :tags, :slug
  end
end
