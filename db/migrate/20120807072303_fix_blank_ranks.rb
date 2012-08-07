class FixBlankRanks < ActiveRecord::Migration
  def change
    change_column_default :songs, :rank, 0
  end
end
