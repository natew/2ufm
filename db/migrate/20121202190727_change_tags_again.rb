class ChangeTagsAgain < ActiveRecord::Migration
  def change
    add_column :tags, :user_id, :integer
    add_column :tags, :source, :string
  end
end
