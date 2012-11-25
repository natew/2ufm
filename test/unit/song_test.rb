require 'test_helper'

class SongTest < ActiveSupport::TestCase
  test "it should strip unecessary remix tags" do
    song = Song.new(song(:remix_strip))
    artists = song.parse_artists
    assert_equals artists, [["Artist1", :remixer], ["Artist2", :remixer], ["Artist3", :remixer], ["Artist", :original]]
  end

  test "it should cleanup download tags" do
    song = Song.new(song(:download_strip))
    name = song.clean_name
    assert_equals name, "Die Young again"
  end
end
