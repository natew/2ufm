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
      .attr('title',playlist.station.title)
      .attr('href',playlist.station.slug);

      // Render playlist
      playlist_template = Mustache.render($('#player-playlist').html(),playlist);
      $('#player-playlist').html(playlist_template).addClass('loaded');
  },

  'mp:play': function mpPlay(event, mp, song) {
    var playlistItem = $('#player-playlist .song-'+song.id),
        w = $(window);

    $('#player-playlist a').removeClass('playing');
    playlistItem.addClass('playing');

    // Update player info
    $('#player-artist-name').html(song.artist_name);
    $('#player-song-name').html(song.name);

    // Update progress bar
    var waveform = mp.curSection().find('.waveform');
    $('#player-progress-waveform, #player-progress-bar canvas').remove();
    if (waveform.length) {
      try {
        $('<img id="player-progress-waveform" src="'+waveform.attr('src')+'" />').appendTo('#player-progress-bar').inverter();
      } catch(error) {
        fn.log(error);
      }
    }

    // Scroll to song
    if (mp.isOnPlayingPage()) {
      var section    = $('#song-'+song.id),
          sectionTop = section.offset().top,
          sectionBot = sectionTop + section.height(),
          windowTop  = w.scrollTop(),
          windowBot  = windowTop + w.height();

      if (sectionTop < (windowTop+60))
        $('html,body').animate({scrollTop:(sectionTop-60)},200);
      else if (sectionBot > windowBot)
        $('html,body').animate({scrollTop:(sectionTop-60)},200);
    }
  },

  'mp:playlist_end': function playlistEnd(event, mp, song) {
    console.log('next');
  }
});