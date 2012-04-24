var w = $(window),
    playlistActive;

// Callbacks
w.on({
  'mp:play': function mpPlay(event, mp, song, another) {
    var playlistItem = $('#player-playlist .song-'+song.id),
        w = $(window);

    $('#player-playlist a').removeClass('playing');
    playlistItem.addClass('playing');

    // Scroll to song
    if (mp.isOnPlayingPage()) {
      var section    = $('#song-'+song.id),
          sectionTop = section.offset().top,
          sectionBot = sectionTop + section.height(),
          windowTop  = w.scrollTop(),
          windowBot  = windowTop + w.height();

      fn.log(section);
      fn.log(sectionTop,windowTop);
      fn.log(sectionBot,windowBot);
      if (sectionTop < (windowTop+60))
        $('html,body').animate({scrollTop:(sectionTop-60)},200);
      else if (sectionBot > windowBot)
        $('html,body').animate({scrollTop:(sectionTop-60)},200);
    }
  }
});