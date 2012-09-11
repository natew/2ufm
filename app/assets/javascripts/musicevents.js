var w = $(window),
    playlistActive;

// Callbacks
w.on({
  'mp:load': function mpLoad(event, mp, song) {
    var playlist = mp.playlist();

    // Update player loaded UI
    $('#main-mid').addClass('loaded');
    $('#player-buttons a').removeClass('disabled');

    // Update now playing button in sidebar nav
    $('#nav-now-playing')
      .html(playlist.station.title)
      .attr('href',playlist.station.slug);

      // Render playlist
      playlist_template = Mustache.render($('#player-playlist').html(),playlist);
      $('#player-playlist').html(playlist_template).addClass('loaded');
  },

  'mp:gotListen': function mpGotListenEvent(event, mp, song) {
    var listen = 'http://2u.fm' + mp.getListenUrl();
    // Update url
    // fn.replaceState(listen);

    // Update share links
    $('#player-share').data('link', listen);
    $('#player-share').data('title', mp.getTitle());
  },

  'mp:play': function mpPlay(event, mp) {
    var song = mp.curSongInfo(),
        playlistItem = $('#player-playlist .song-'+song.id),
        w = $(window),
        song_url = $('#song-' + song.id + ' .name a').attr('href'),
        curSection = mp.curSection(),
        html_artists = null;

    $('#player-playlist a').removeClass('playing');
    playlistItem.addClass('playing');

    // Update player info
    if (curSection) {
      var em = curSection.find('.name em'),
          artist = curSection.find('.artist').html() || '',
          other_artists = (em && em.length) ? em.html() : '',
          separator = (artist.length && other_artists.length) ? ', ' : '';
      html_artists = artist.length ? artist + separator + other_artists : other_artists
    }

    $('#player-artist-name').html(html_artists || song.artist_name);
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
    }, 100);
  },

  'mp:playlist_end': function playlistEnd(event, mp, song) {
    mp.playSection($('.playlist-song:visible section:first'));
  }
});