class UpdateSongsSimilarSongs < ActiveRecord::Migration
  def up
    add_column :songs, :blog_broadcasts_count, :integer

    Song.skip_callback(:save, :before, :set_rank)

    Song.working.each do |song|
      song.set_match_name
      song.save
    end

    # First set matching ids
    Song.working.order('id asc').each do |song|
      song.save if song.update_matching_songs
    end

    Song.set_callback(:save, :before, :set_rank)
  end

  def down
    remove_column :songs, :blog_broadcasts_count
  end
end
