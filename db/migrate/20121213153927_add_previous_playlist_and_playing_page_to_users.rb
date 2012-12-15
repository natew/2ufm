class AddPreviousPlaylistAndPlayingPageToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_playlist, :text
    add_column :users, :last_playlist_id, :string
    add_column :users, :last_playing_page, :string
  end
end
