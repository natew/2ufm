class ChangeSongsHashToToken < ActiveRecord::Migration
  def up
    rename_column :songs, :hash, :token

    Song.where('songs.token is null').each do |song|
      song.delay.set_token_and_save
    end
  end

  def down
    rename_column :songs, :token, :hash
  end
end
