var mp = (function() {
  //
  // Variables
  //
  var playlist = null,
      playlistID = null,
      playlistIndex = null,
      curSection = null,
      curSongInfo,
      curSong,
      isPlaying =  false,
      dragging_position = false,
      dragging_x,
      curPage,
      playingPage,
      smReady = false,
      delayStart = false,
      volume = 100,
      playlist_template = '',
      self = this,
      time = 0;

  // Elements
  var pl = {
    bar: $('#bar'),
    playlist: $('#player-playlist'),
    loaded: $('#player-progress-loaded'),
    position: $('#player-progress-position'),
    handle: $('#player-progress-grabber'),
    player: $('#player'),
    song: $('#player-song'),
    play: $('#player-play'),
    invite: $('#player-invite'),
    volume: $('#player-volume')
  };

  // Soundmanager
  soundManager.url = '/swfs/soundmanager2_debug.swf';
  //soundManager.flashVersion = 9; // optional: shiny features (default = 8)
  soundManager.useFlashBlock = false; // optionally, enable when you're ready to dive in
  soundManager.debugMode = true;
  //soundManager.useFastPolling = true;
  //soundManager.useHighPerformance = true;
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
    playSection: function(section) {
      this.stop();
      curSection = section;
      fn.log(curSection);
      this.load();
      this.play();
    },

    // Load playlist
    load: function() {
      if (!curSection) curSection = $('.playlist section:first,.playlist tbody tr:first');
      if (curSection) {
        fn.log('loading playlist');

        // Remember this page
        playingPage = curPage;
        $('#player-goto').attr('href',playingPage).removeClass('disabled');

        // Get playlist info
        playlistIndex = curSection.data('index');
        playlistID = curSection.data('station');
        playlist   = $('#playlist-'+playlistID).data('playlist');

        fn.log(playlist);
        fn.log(pl);

        $('#main-mid').addClass('loaded');

        // Render playlist
        // playlist_template = Mustache.render(pl.playlist.html(),playlist);
        // pl.playlist.html(playlist_template);
        // pl.playlist.addClass('loaded');

        fn.log('playlist loaded: '+playlistID);
      }
    },

    // Play song
    play: function() {
      if (!smReady) {
        delayStart = true;
      } else {
        // Load
        fn.log('Playing... playlist', playlist);
        if (!playlist) this.load();
        fn.log('After load... playlist', playlist);

        if (playlist && playlistIndex < playlist.songs.length) {
          // Load song
          fn.log('playing song at index: '+playlistIndex);
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
            curSong.setPosition(time*1000);
            time = 0;
          }

          // Play
          curSong.play();
          return true;
        } else {
          curSection = null;
          this.refresh();
          return false;
        }
      }
    },

    playSong: function(index) {
      if (playlist) {
        playlistIndex = index;
        this.stop();
        this.play();
      }
    },

    stop: function() {
      if (isPlaying) {
        curSong.stop();
        soundManager.stopAll();
      }
    },

    pause: function() {
      if (isPlaying) {
        curSong.pause();
      }
    },

    toggle: function() {
      if (isPlaying) curSong.togglePause();
      else this.play();
    },

    next: function() {
      if (curSection) var next = curSection.next();
      this.stop();
      this.setCurSectionInactive();
      if (next) {
        curSection = next;
        this.setCurSectionActive();
      }
      playlistIndex++;
      this.play();
    },

    prev: function() {
      if (curSection) prev = curSection.prev();
      this.stop();
      this.setCurSectionInactive();
      if (prev) {
        curSection = prev;
        this.setCurSectionActive();
      }
      playlistIndex--;
      this.play();
    },

    refresh: function() {
      if (isPlaying) {
        var title = curSongInfo.artist + ' - ' + curSongInfo.name;
        pl.player.addClass('playing');
        pl.song.html(title);
        pl.play.html('5');
        // <title>
        icon = isPlaying ? '\u25BA' : '\u25FC';
        $('title').html(icon + ' ' + title);
      } else {
        pl.player.removeClass('playing');
        pl.play.html('4');
      }
    },

    setCurSectionActive: function() {
      if (curSection) {
        curSection.addClass('playing');
        curSection.find('.play-song').html('5');
      }
    },

    setCurSectionInactive: function() {
      if (curSection) {
        curSection.removeClass('playing');
        curSection.find('.play-song').html('4');
      }
    },

    updateProgress: function(percent) {
      pl.position.attr('width',percent+'%');
      fn.log(curSong.durationEstimate, (percent/100), curSong.durationEstimate*(percent/100));
      curSong.setPosition(curSong.durationEstimate*(percent/100));
    },

    volumeToggle: function() {
      if (volume == 100) {
        pl.volume.html('<');
        volume = 0;
        this.setVolume();
      } else {
        pl.volume.html('>');
        volume = 100;
        this.setVolume();
      }
    },

    setVolume: function() {
      if (curSong) {
        curSong.setVolume(volume);
      }
    },

    startDrag: function(event) {
      if (!event) var event = window.event;
      element = event.target || event.srcElement;

      fn.log('startdrag: ' + element.id)
      if (element.id.match(/handle/)) {
        dragging_position = true;
        pl.handle.unbind('mousemove').bind('mousemove', this.followDrag);
        pl.handle.unbind('mouseup').bind('mouseup', this.endDrag);
      }

      return false;
    },

    endDrag: function(event) {
      if (!event) var event = window.event; // IE Fix
      element = event.target || event.srcElement;

      dragging_position = false;
      pl.handle.unbind('mousemove');
      pl.handle.unbind('mouseup');

      if (element.id.match(/handle/)) {
        //player.updateProgress(event, element);
      }

      return false;
    },

    followDrag: function(event) {
      if (!event) var event = window.event;
      element = event.target || event.srcElement;

      var x      = parseInt(event.clientX),
          offset = pl.handle.offset().left,
          width  = pl.handle.width(),
          curPos = curSong.position,
          newPos = Math.round(((x - offset) / width) * 100);

      fn.log('followdrag: ' + x + ' / ' + newPos + '%');

      player.updateProgress(newPos);
      if (newPos >= 100 || newPos <= 0) this.endDrag();
    }
  };


  //
  // Events
  //
  var events = {
    play: function() {
      isPlaying = true;
      pl.bar.addClass('loaded');
      player.setCurSectionActive();
      player.refresh();

      // Scrobbling
      $.ajax({
        type: 'POST',
        url: '/listens',
        data: { listen: { song_id: curSongInfo.id, user_id: $('#current_user').data('id'), url: curPage } },
        success: function(data) {
          pl.invite.attr('href','/l/'+data);
          pl.invite.removeClass('disabled');
          fn.clipboard();
        },
        dataType: 'html'
      });
    },

    stop: function() {
      isPlaying = false;
      player.setCurSectionInactive();
      curSection = null;
      player.refresh();
    },

    pause: function() {
      isPlaying = false;
      player.setCurSectionInactive();
      player.refresh();
    },

    resume: function() {
      isPlaying = true;
      player.setCurSectionActive();
      player.refresh();
    },

    finish: function() {
      player.setCurSectionInactive();
      player.next();
    },

    whileloading: function() {
      function doWork() {
        pl.loaded.css('width',(Math.round((this.bytesLoaded/this.bytesTotal)*100))+'%');
      }
      doWork.apply(this);
    },

    whileplaying: function() {
      //updateTime.apply(this);
      pl.position.css('width',(Math.round(this.position/this.durationEstimate*1000)/10)+'%');
    },

    metadata: function() {

    },

    onload: function(success) {
      if (!success) {
        var failedSection = curSection.addClass('failed');
        if (curPage == playingPage) player.next();
        $.post('songs/'+curSongInfo.id, { failing: 'true' });
      }
    }
  };


  //
  // API
  //

  return {

    setPage: function(url) {
      curPage = url;
      if (curPage && curPage == playingPage) {
        fn.log('RETURNED!!!!!!!!!!!!');
        // If we return to the page we started playing from, re-activate current song
        curSection = $(document).find('#song-' + curSongInfo.id);
        fn.log(curSongInfo.id,curSection);
        player.setCurSectionActive();
      } else {
        curSection = null;
      }
    },

    playSong: function(index) {
      player.playSong(index);
    },

    toggle: function() {
      var played = player.toggle();
      return isPlaying;
    },

    stop: function() {
      player.stop();
    },

    pause: function() {
      player.pause();
    },

    next: function() {
      player.next();
    },

    prev: function() {
      player.prev();
    },

    volumeToggle: function() {
      player.volumeToggle();
    },

    setTime: function(seconds) {
      time = seconds;
    },

    playSection: function(section) {
      $('.playlist section:first-child').removeClass('show-play');
      player.playSection(section);
    },

    getSection: function() {
      return curSection;
    },

    getPlaylist: function() {
      return playlist;
    },

    getPlayingPage: function() {
      return playingPage;
    },

    getCurPage: function() {

    }

  };

}());