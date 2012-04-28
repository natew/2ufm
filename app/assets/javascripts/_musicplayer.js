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
      isPlaying = false,
      dragging_position = false,
      dragging_percent,
      curPage,
      playingPage,
      smReady = false,
      delayStart = false,
      volume = 100,
      playlist_template = '',
      time = 0,
      marqueeInterval;

  // Elements
  var pl = {
    bar: $('#bar'),
    playlist: $('#player-playlist'),
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
  //soundManager.flashVersion = 9; // optional: shiny features (default = 8)
  soundManager.useFlashBlock = false; // optionally, enable when you're ready to dive in
  soundManager.debugMode = false;
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
    playSection: function playSection(section) {
      this.stop();
      curSection = section;
      fn.log(curSection);
      this.load();
      this.play();
    },

    // Load playlist
    load: function load() {
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
        playlist_template = Mustache.render(pl.playlist.html(),playlist);
        pl.playlist.html(playlist_template);
        pl.playlist.addClass('loaded');

        fn.log('playlist loaded: '+playlistID);
      }
    },

    // Play song
    play: function play() {
      if (!smReady) {
        delayStart = true;
      } else {
        // Load
        if (!playlist) this.load();
        fn.log('Playlist...', playlist);

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
            curSong.setPosition(time*1000);
            time = 0;
          }

          // Play
          curSong.play();

          // For scrolling animation
          this.marquee(true);
          return true;
        } else {
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
        this.marquee(false);
        soundManager.stopAll();
      }
    },

    pause: function pause() {
      if (isPlaying) {
        curSong.pause();
        this.marquee(false);
      }
    },

    next: function next() {
      if (curSection) {
        var next = curSection.next();
        this.stop();
        this.setCurSectionInactive();
        if (next.length) {
          curSection = next;
          this.setCurSectionActive();
          playlistIndex++;
          this.play();
        } else {
          curSection = null;
        }
      }
    },

    prev: function prev() {
      if (curSection) {
        previous = curSection.prev();
        this.stop();
        this.setCurSectionInactive();
        if (previous.length) {
          curSection = previous;
          this.setCurSectionActive();
          playlistIndex--;
          this.play();
        } else {
          curSection = null;
        }
      }
    },

    refresh: function refresh() {
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

    marquee: function marquee(start) {
      if (start) {
        pl.song.removeClass('calculated');
        var metaWidth   = (pl.meta.width()-28),
            titleWidth  = pl.song.width(),
            totalIndent = titleWidth-metaWidth,
            curIndent   = 0,
            comingBack  = false;
        pl.song.addClass('calculated');

        if (totalIndent > 0) {
          marqueeInterval = setInterval(function() {
            if (curIndent < totalIndent && !comingBack) {
              curIndent++;
              pl.song.css('text-indent', '-'+curIndent+'px');
            } else {
              comingBack = true;
              curIndent--;
              if (curIndent == 0) comingBack = false;
              pl.song.css('text-indent', '-'+curIndent+'px');
            }
          },35);
        }
      } else {
        clearInterval(marqueeInterval);
        pl.song.css('text-indent', '0px');
      }
    },

    setCurSectionActive: function setCurSectionActive() {
      if (curSection) {
        curSection.addClass('playing');
      }
    },

    setCurSectionInactive: function setCurSectionInactive() {
      if (curSection) {
        curSection.removeClass('playing');
      }
    },

    volumeToggle: function volumeToggle() {
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
      e.preventDefault();
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
      var duration     = curSong.duration || curSong.durationEstimate,
          milliseconds = Math.round(duration*(dragging_percent/100));
      // fn.log(dragging_percent/100, duration, milliseconds);
      pl.position.attr('width',dragging_percent+'%');
      curSong.setPosition(milliseconds);
    }
  };


  //
  // Events
  //
  var events = {
    play: function play() {
      isPlaying = true;
      pl.bar.addClass('loaded');
      player.setCurSectionActive();
      player.refresh();
      w.trigger('mp:play', [mp, curSongInfo]);

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

    stop: function stop() {
      isPlaying = false;
      player.setCurSectionInactive();
      curSection = null;
      player.refresh();
    },

    pause: function pause() {
      isPlaying = false;
      player.setCurSectionInactive();
      player.refresh();
    },

    resume: function resume() {
      isPlaying = true;
      player.setCurSectionActive();
      player.refresh();
    },

    finish: function finish() {
      player.setCurSectionInactive();
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
        curSection.addClass('failed');
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

    isOnPlayingPage: function() {
      return (curPage == playingPage);
    },

    playSong: function(index) {
      player.playSong(index);
    },

    toggle: function() {
      if (isPlaying) player.pause();
      else player.play();
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

    section: function() {
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
    }

  };

}(window, mp));