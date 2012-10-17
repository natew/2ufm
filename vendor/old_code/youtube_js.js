$.ajax({
  url: 'http://gdata.youtube.com/feeds/mobile/videos?alt=json-in-script&q=' + toYoutubeSearch(song.artist_name + ' ' + song.name),
  dataType: 'jsonp',
  success: function youTubeSuccess(data) {
    fn.log(data);
    if (data.feed.entry) {
      curSection.find('.reviews').after('<iframe width="420" height="315" src="'+data.feed.entry[0].id.$t+'"></iframe>')
    }
   }
});