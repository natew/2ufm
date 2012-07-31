var mp = (function() {

  //
  // Variables
  //
  var w = $(window),
      playlist,
      playlistID,
      playlistIndex,
      curSection,
      curSongInfo,
      curSong,
      listenURL,
      isPlaying = false,
      dragging_position = false,
      dragging_percent,
      curPage,
      playingPage,
      smReady = false,
      delayStart = false,
      volume = $.cookie('volume') || $.cookie('volume', 100),
      time = 0,
      autoPlay = false,
      hasMoved = false;

  // Elements
  var pl = {
    loaded: $('#player-progress-loaded'),
    position: $('#player-progress-position'),
    handle: $('#player-progress-grabber'),
    player: $('#player'),
    song: $('#player-song'),
    meta: $('#player-meta'),
    play: $('#player-play'),
    invite: $('#player-invite'),
    volume: $('#player-volume')
  };

  // Soundmanager
  soundManager.url = '/swfs/soundmanager2_debug.swf';
  soundManager.useFlashBlock = false;
  soundManager.debugMode = false;
  soundManager.useHTML5Audio = true;
  soundManager.preferFlash = false;
  soundManager.onready(function() {
    smReady = true;
    if (delayStart) player.play();
    if (soundManager.supported()) {
      pl.handle.bind('mousedown', player.startDrag);
      pl.handle.bind('mouseup', player.endDrag);
    } else {
      alert('Your browser does not support audio playback');
    }
  });


  //
  // Player functions
  //
  var player = {
    // Play a section
    playSection: function playSection(section) {
      if (!section || !section.length) return false;
      if (section.is('.playing')) {
        this.toggle();
      } else {
        this.stop();
        if (curSection && curSection.length) this.setCurSection('inactive');
        curSection = section;
        fn.log(curSection);
        this.load();
        hasMoved = false;
        return this.play();
      }
    },

    // Load playlist
    load: function load() {
      fn.log(curSection);
      if (!curSection) curSection = $('.playlist:visible section:first');
      if (curSection.length) {
        playlistIndex = curSection.data('index');
        playlistID = curSection.data('station');

        // Checking to see if first time loaded, or if loading new playlist
        if (typeof playlist === 'undefined' || playlist.id != playlistID) {
          fn.log('loading', playlistIndex, playlistID);

          // Remember this page
          playingPage = curPage;

          // Get new playlist
          playlist = $('#playlist-' + playlistID).data('playlist');

          // Add indices
          for (var i = 0; i < playlist.songs.length; i++) {
            playlist.songs[i].index = i;
          }

          // Callback
          w.trigger('mp:load', player.state());
          fn.log('loaded',playlist,playlistID);
          return true;
        }
      }
    },

    // Play song
    play: function play() {
      if (!smReady) {
        delayStart = true;
      }
      else {
        // Load
        if (!playlist) this.load();
        fn.log('Playlist...', playlist, 'Index...', playlistIndex, 'Songs length...', playlist.songs.length);

        if (playlist && playlistIndex < playlist.songs.length) {
          // Load song
          fn.log('Song at index '+playlistIndex);
          curSongInfo = playlist.songs[playlistIndex];
          curSong = soundManager.createSound({
            id:curSongInfo.id,
            url:curSongInfo.url,
            onplay:events.play,
            onstop:events.stop,
            onpause:events.pause,
            onresume:events.resume,
            onfinish:events.finish,
            whileloading:events.whileloading,
            whileplaying:events.whileplaying,
            onmetadata:events.metadata,
            onload:events.onload,
            volume:volume
          });

          // If we have a time set
          if (time > 0) {
            curSong.setPosition(time * 1000);
            time = 0;
          }

          // Play
          curSong.play();
          return true;
        }
        else {
          fn.log('playing fail');
          curSection = null;
          this.refresh();
          return false;
        }
      }
    },

    playSong: function playSong(index) {
      if (playlist) {
        playlistIndex = index;
        this.stop();
        this.play();
      }
    },

    stop: function stop() {
      if (isPlaying) {
        curSong.stop();
        soundManager.stopAll();
      }
    },

    pause: function pause() {
      if (isPlaying) {
        curSong.pause();
      }
    },

    toggle: function toggle() {
      if (isPlaying) this.pause();
      else this.play();
    },

    next: function next() {
      if (this.playSection(curSection.next())) return true;
      else return this.toPlaylist('next');
    },

    prev: function prev() {
      if (this.playSection(curSection.prev())) return true;
      else return this.toPlaylist('prev');
    },

    toPlaylist: function toPlaylist(direction) {
      fn.log(direction);
      var fw = direction == 'next' ? true : false,
          increment = fw ? 1 : -1,
          section = fw ? 'first' : 'last',
          curPlaylistInfo = playlistID.split('-'),
          nextPlaylistInfo = curPlaylistInfo[0] + '-' + (parseInt(curPlaylistInfo[1],10) + increment),
          nextSection = $('#playlist-' + nextPlaylistInfo + ' section:' + section);

      if (nextSection.length) {
        this.playSection(nextSection);
        return true;
      } else {
        curSection = null;
        return false;
      }
    },

    refresh: function refresh() {
      var icon  = isPlaying ? '\u25BA' : '\u25FC';

      $('title').html(icon + ' ' + this.getTitle());
      if (isPlaying) {
        pl.player.addClass('playing');
        pl.play.html('<span>5</span>');
      } else {
        pl.player.removeClass('playing');
        pl.play.html('<span>4</span>');
      }
    },

    getTitle: function getTitle() {
      if (curSongInfo) return curSongInfo.artist_name + ' - ' + curSongInfo.name;
      return '';
    },

    setCurSection: function setCurSection(status) {
      var statuses = {
        'playing':  ['paused', 'active playing listened-to'],
        'paused':   ['playing', 'paused'],
        'inactive': ['paused playing active', '']
      }

      fn.log('setting song ' + curSongInfo.name + ' to ' + status);

      if (curSection) {
        curSection.removeClass(statuses[status][0]).addClass(statuses[status][1]);
      }
    },

    volumeToggle: function volumeToggle() {
      if (volume == 100) {
        pl.volume.html('<');
        volume = 0;
        $.cookie('volume', volume);
        this.setVolume();
      } else {
        pl.volume.html('>');
        volume = 100;
        $.cookie('volume', volume);
        this.setVolume();
      }
    },

    setVolume: function setVolume() {
      if (curSong) {
        curSong.setVolume(volume);
      }
    },

    startDrag: function startDrag(e) {
      e.preventDefault();
      dragging_position = true;
      pl.handle.unbind('mousemove').bind('mousemove', player.followDrag);
      pl.handle.unbind('mouseup').bind('mouseup', player.endDrag);
    },

    endDrag: function endDrag(e) {
      dragging_position = false;
      pl.handle.unbind('mousemove');
      pl.handle.unbind('mouseup');
      player.followDrag(e);
      player.updateProgress();
    },

    followDrag: function followDrag(e) {
      var e      = e ? e : window.event,
          x      = parseInt(e.clientX),
          offset = pl.handle.offset().left,
          width  = pl.handle.width(),
          newPos = Math.round(((x - offset) / width) * 100);

      // fn.log(e,x,offset,width,newPos);
      dragging_percent = newPos;
      if (dragging_percent >= 99 || dragging_percent <= 0) player.endDrag();
      else player.updateProgress();
    },

    updateProgress: function updateProgress() {
      var duration     = curSong.duration || curSong.durationEstimate || 0,
          milliseconds = Math.round(duration * (dragging_percent / 100));
      // fn.log(dragging_percent/100, duration, milliseconds);
      pl.position.attr('width', dragging_percent + '%');
      curSong.setPosition(milliseconds);
    },

    state: function() {
      return [mp, curSongInfo];
    }
  };


  //
  // Events
  //
  var events = {
    play: function play() {
      isPlaying = true;
      pl.player.addClass('loaded');
      player.setCurSection('playing');
      player.refresh();
      w.trigger('mp:play', player.state());

      // Scrobbling
      $.ajax({
        type: 'POST',
        url: '/listens',
        data: { listen: { song_id: curSongInfo.id, user_id: $('#current_user').data('id'), url: curPage } },
        success: function playSuccess(data) {
          listenURL = '/l/'+data;
          pl.invite.attr('href',listenURL);
          pl.invite.removeClass('disabled');
          fn.clipboard('player-invite');
          w.trigger('mp:gotListen', player.state());
        },
        dataType: 'html'
      });
    },

    stop: function stop() {
      isPlaying = false;
      player.setCurSection('inactive');
      curSection = null;
      player.refresh();
    },

    pause: function pause() {
      isPlaying = false;
      player.setCurSection('paused');
      player.refresh();
    },

    resume: function resume() {
      isPlaying = true;
      player.setCurSection('playing');
      player.refresh();
    },

    finish: function finish() {
      player.next();
    },

    whileloading: function whileloading() {
      function doWork() {
        pl.loaded.css('width',(Math.round((this.bytesLoaded/this.bytesTotal)*100))+'%');
      }
      doWork.apply(this);
    },

    whileplaying: function whileplaying() {
      //updateTime.apply(this);
      pl.position.css('width',(Math.round(this.position/this.durationEstimate*1000)/10)+'%');
    },

    metadata: function metadata() {

    },

    onload: function onload(success) {
      if (!success) {
        if (curSection) curSection.addClass('failed');
        if (curPage == playingPage) player.next();
        $.post('songs/'+curSongInfo.id, { failing: 'true' });
      }
    }
  };


  //
  // API
  //

  return {

    setPage: function setPage(url) {
      curPage = url;
      if (isPlaying && (curPage == playingPage || curPage.split('/')[1] == 'songs')) {
        // If we return to the page we started playing from, re-activate current song
        curSection = $(document).find('#song-' + curSongInfo.id);
        if (curSection) player.setCurSection('playing');
      }
      else {
        curSection = null;

        if (autoPlay) {
          fn.log('AUTO PLAY');
          player.playSection($('.playlist:first section:first'));
          autoPlay = false;
        }
      }
    },

    getPage: function () {
      return curPage;
    },

    getListenUrl: function() {
      return listenURL;
    },

    isOnPlayingPage: function() {
      return (curPage == playingPage);
    },

    playSong: function(index) {
      player.playSong(index);
    },

    toggle: function() {
      player.toggle();
      return isPlaying;
    },

    stop: function() {
      player.stop();
    },

    pause: function() {
      player.pause();
    },

    next: function() {
      return player.next();
    },

    prev: function() {
      player.prev();
    },

    isPlaying: function() {
      return isPlaying;
    },

    volumeToggle: function() {
      player.volumeToggle();
    },

    setTime: function(seconds) {
      time = seconds;
    },

    playSection: function(section) {
      player.playSection(section);
    },

    curSection: function() {
      return curSection;
    },

    playlist: function() {
      return playlist;
    },

    playingPage: function() {
      return playingPage;
    },

    curPage: function() {
      return curPage;
    },

    curSong: function() {
      return curSong;
    },

    curSongInfo: function() {
      return curSongInfo;
    },

    getTitle: function() {
      return player.getTitle();
    },

    setAutoPlay: function(value) {
      autoPlay = value;
    },

    autoPlay: function() {
      return autoPlay;
    },

    hasMoved: function (val) {
      hasMoved = val;
    },

    getHasMoved: function() {
      return hasMoved;
    }

  };

}(window, mp));