var w = $(window),
    playlistActive,
    playlistTemplate = $('#player-playlist-template').html();

// Callbacks
w.on({
  'mp:load': function mpLoad(event) {
    var playlist = mp.playlist();

    // Update player loaded UI
    $('#main-mid').addClass('loaded');
    $('#buttons a').removeClass('disabled');

    // Update now playing button in sidebar nav
    $('#nav-now-playing')
      .html(playlist.station.title)
      .attr('href',playlist.station.slug);

      // Render playlist
      playerPlaylist = Mustache.render(playlistTemplate, playlist);
      $('#player-playlist').html(playerPlaylist).addClass('loaded');
  },

  'mp:got:listen': function mpGotListenEvent(event) {
    var listen = mp.getListenUrl(),
        listenUrl = 'http://' + location.host + '/l/' + listen;

    // Update url
    // fn.replaceState(listen);

    if (mp.curSection() && mp.curSection().length)
      mp.curSection().attr('data-listen', listen);

    // Update share links
    $('#player-share')
      .data('link', listenUrl)
      .data('title', mp.getTitle());

    updatePlayerShare();
    if (activeParent && activeParent.is('.song-share')) {
      fn.log('active parent', activeParent);
      updateShare(activeParent);
    }
  },

  'mp:played': function mpPlay(event) {
    var song = mp.curSongInfo(),
        playlistItem = $('#player-playlist .song-' + song.id),
        w = $(window),
        song_url = $('#song-' + song.id + ' .name a').attr('href');

    fn.log('mp:played', song, playlistItem);
    $('#player').removeClass('loading');

    // Update playlist
    $('#player-playlist a').removeClass('playing');
    playlistItem.addClass('playing');

    // Update broadcast button
    updateBroadcastButton(mp.playlist().station.id, song.id);

    // Update song name link
    $('#player-song-name a')
      .html(song.name)
      .attr('href', mp.curPlaylistUrl());

    // Update page url
    fn.replaceState(mp.playingPage());
  },

  'mp:play': function(event) {
    var song = mp.curSongInfo(),
        section = mp.curSection(),
        html_artists;

    $('#player').addClass('loading');
    $('#buttons .broadcast').removeClass('remove');

    doPlaysActions();

    // Update player artists
    var artists = section && section.length ? section.find('.artist').html() || '' : '';
    $('#player-artist-name').html(artists || song.artist_name);

    scrollToPlayingSong(section);
  },

  'mp:play:soundcloud': function mpPlaySoundcloud(event, data) {
    fn.log(mp, data);
    if (!mp.curSection()) return;
    if (mp.curSection().is('.soundcloud-loaded')) return;
    fn.log(data.permalink_url, data['permalink_url'])
    $('#sc-button-template a')
      .clone()
      .attr('href', data.permalink_url)
      .attr('title', (data.user ? data.user.username : '') + ' on SoundCloud')
      .appendTo(mp.curSection().find('.song-controls'));
    mp.curSection().addClass('soundcloud-loaded');
  },

  'mp:playlist:end': function playlistEnd(event, mp, song) {
    mp.playSection($('.playlist-song:visible section:first'));
  }
});