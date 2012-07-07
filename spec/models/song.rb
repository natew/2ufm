describe Song do
  describe ".playlist_order_broadcasted" do
    it "includes the most recently broadcasted songs" do
      song = Song.create!(:url => 'http://files2.earmilk.com/tracks/MjAxMi0wNy9EaUJlbGxhLUpvaG5ueS1NYWMtLS1XZS1BcmUtQS1UZWVuYWdlLVdhc3RlbGFuZC0oRnVuLXgtVGhlLVdoby14LUhhcmR3ZWxsLXgtVGllc3RvLVNob3d0ZWsteC1QaGlsLUNvbGxpbnMpLS1FTTA3MTIubXAz.mp3')
      Song.playlist_order_broadcasted.first.should eq(song)
    end
  end
end