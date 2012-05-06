var w = $(window),
    playlistActive;

// Callbacks
w.on({
  'mp:play': function mpPlay(event, mp, song, another) {
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
  }
});