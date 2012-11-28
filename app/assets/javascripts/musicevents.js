var w = $(window),
    playlistActive,
    playlistTemplate = $('#player-playlist-template').html();

// Callbacks
w.on({
  'mp:load': function mpLoad(event, mp) {
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

  'mp:got:listen': function mpGotListenEvent(event, mp) {
    var listen = mp.getListenUrl(),
        listenUrl = 'http://' + location.host + '/l/' + listen;

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
        song_url = $('#song-' + song.id + ' .name a').attr('href');

    $('#player').removeClass('loading');

    // Update playlist
    $('#player-playlist a').removeClass('playing');
    playlistItem.addClass('playing');

    // Update broadcast button
    updateBroadcastButton(mp.playlist().station.id, song.id);

    // Update page url
    fn.replaceState(mp.playingPage());
  },

  'mp:play': function(event, mp) {
    var song = mp.curSongInfo(),
        section = mp.curSection(),
        html_artists;

    $('#player').addClass('loading');
    $('#player-buttons .broadcast').removeClass('remove');

    doPlaysActions();

    // Update player artists
    if (section && section.length) {
      var em = section.find('.name em'),
          artist = section.find('.artist').html() || '',
          other_artists = (em && em.length) ? em.html() : '',
          separator = (artist.length && other_artists.length) ? ', ' : '';
      html_artists = artist.length ? artist + separator + other_artists : other_artists;
    }

    $('#player-artist-name').html(html_artists || song.artist_name);
    $('#player-song-name a').attr('href', mp.curPlaylistUrl()).html(song.name);

    scrollToPlayingSong(section);
  },

  'mp:play:soundcloud': function mpPlaySoundcloud(event, mp, data) {
    fn.log(mp, data);
    if (mp.curSection().is('.soundcloud-loaded')) return;
    fn.log(data.permalink_url, data['permalink_url'])
    $('#sc-button-template a')
      .clone()
      .attr('href', data.permalink_url)
      .appendTo(mp.curSection().find('.song-controls'));
    mp.curSection().addClass('soundcloud-loaded');
  },

  'mp:playlist:end': function playlistEnd(event, mp, song) {
    mp.playSection($('.playlist-song:visible section:first'));
  }
});