class DeleteMatchingFiles < ActiveRecord::Migration
  def up
    Song.where('matching_id != id').each do |song|
      song.delete_file_if_matching
    end
  end

  def down
  end
end
