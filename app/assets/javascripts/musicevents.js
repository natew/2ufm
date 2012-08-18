var w = $(window),
    playlistActive;

// Callbacks
w.on({
  'mp:load': function mpLoad(event, mp, song) {
    var playlist = mp.playlist();

    // Update player loaded UI
    $('#main-mid').addClass('loaded');
    $('#nav-music').removeClass('disabled');

    // Update now playing button in sidebar nav
    $('#nav-now-playing')
      .html(playlist.station.title)
      .attr('href',playlist.station.slug);

      // Render playlist
      playlist_template = Mustache.render($('#player-playlist').html(),playlist);
      $('#player-playlist').html(playlist_template).addClass('loaded');
  },

  'mp:gotListen': function mpGotListenEvent(event, mp, song) {
    // Update url
    // fn.replaceState(mp.getListenUrl());

    // Share links
    var url = encodeURIComponent('http://2u.fm' + mp.getListenUrl()),
        text = encodeURIComponent('Listening to ' + (mp.getTitle() || 'nothin')),
        tweet = ['http://twitter.com/share?text='
                  , text
                  , "&url="
                  , url
                ].join(''),
        facebook = ['https://www.facebook.com/sharer.php?u='
                  , url
                  , '&t='
                  , text
                ].join('');

    $('#player-invite-twitter').attr('href', tweet);
    $('#player-invite-facebook').attr('href', facebook);

    // Undisable
    $('#invite-container').removeClass('disabled');
  },

  'mp:play': function mpPlay(event, mp, song) {
    var playlistItem = $('#player-playlist .song-'+song.id),
        w = $(window),
        song_url = $('#song-' + song.id + ' .name a').attr('href');

    $('#player-playlist a').removeClass('playing');
    playlistItem.addClass('playing');

    // Update player info
    $('#invite-container').addClass('disabled');
    $('#player-artist-name').html(song.artist_name);
    $('#player-song-name a').attr('href', mp.curPlaylistUrl()).html(song.name);

    // Scroll to song
    setTimeout(function() {
      if (mp.isOnPlayingPage() && !mp.getHasMoved()) {
        fn.log('scroll to song');
        var section    = $('#song-' + song.id);

        if (section.length) {
          var sectionTop = section.offset().top,
              sectionBot = sectionTop + section.height(),
              windowTop  = w.scrollTop(),
              windowBot  = windowTop + w.height();

          if (sectionTop < (windowTop + 60)) fn.scrollTo(sectionTop - 200);
          else if (sectionBot > windowBot) fn.scrollTo(sectionTop - 200);
        }
      }
    }, 200);
  },

  'mp:playlist_end': function playlistEnd(event, mp, song) {
    console.log('end of playlist');
  }
});