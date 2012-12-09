class CategorizeSongs < ActiveRecord::Migration
  def up
    Song.working.each do |song|
      song.delayed_update_category
    end
  end

  def down
  end
end
