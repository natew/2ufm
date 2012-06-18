class ChangeAbsoluteUrlToText < ActiveRecord::Migration
  def up
    change_column :songs, :absolute_url, :text
  end

  def down
    change_column :songs, :absolute_url, :string
  end
end
