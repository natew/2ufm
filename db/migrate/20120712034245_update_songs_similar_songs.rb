class UpdateSongsSimilarSongs < ActiveRecord::Migration
  def up
    add_column :songs, :blog_broadcasts_count, :integer, :default => 0
    add_column :songs, :match_name, :string

    Song.skip_callback(:save, :before, :set_rank)

    # First set matching ids
    Song.working.order('id asc').each do |song|
      song.save if song.update_matching_songs
    end

    Song.set_callback(:save, :before, :set_rank)
  end

  def down
    remove_column :songs, :blog_broadcasts_count
    remove_column :songs, :match_name
  end
end
