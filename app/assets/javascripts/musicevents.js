var w = $(window),
    playlistActive,
    playlistTemplate = $('#player-playlist-template').html();

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
      playerPlaylist = Mustache.render(playlistTemplate, playlist);
      $('#player-playlist').html(playerPlaylist).addClass('loaded');
  },

  'mp:gotListen': function mpGotListenEvent(event, mp, song) {
    var listen = mp.getListenUrl(),
        listenUrl = 'http://2u.fm/l/' + listen;

    // Update url
    // fn.replaceState(listen);

    mp.curSection().attr('data-listen', listen);

    // Update share links
    $('#player-share').data('link', listenUrl);
    $('#player-share').data('title', mp.getTitle());
  },

  'mp:played': function mpPlay(event, mp) {
    var song = mp.curSongInfo(),
        playlistItem = $('#player-playlist .song-' + song.id),
        w = $(window),
        song_url = $('#song-' + song.id + ' .name a').attr('href'),
        curSection = mp.curSection(),
        html_artists = null;

    // Update playlist
    $('#player-playlist a').removeClass('playing');
    playlistItem.addClass('playing');

    // Update broadcast button
    updateBroadcastButton(mp.playlist().station.id, song.id);

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
  },

  'mp:play': function(event, mp) {
    var section = mp.curSection();
    $('#player-buttons .broadcast').removeClass('remove');

    // Scroll to song
    setTimeout(function() {
      if ( mp.isOnPlayingPage() && (!mp.getHasMoved() || mp.usedKeyboard()) ) {
        fn.log('scroll to song');
        if (section.length) {
          var sectionTop = section.offset().top,
              sectionBot = sectionTop + section.height(),
              windowTop  = w.scrollTop(),
              windowBot  = windowTop + w.height();

          if (sectionTop < (windowTop + 220)) fn.scrollTo(section);
          else if (sectionBot > (windowBot - 40)) fn.scrollTo(section);
        }
      }
    }, 200);
  },

  'mp:playlist_end': function playlistEnd(event, mp, song) {
    mp.playSection($('.playlist-song:visible section:first'));
  }
});