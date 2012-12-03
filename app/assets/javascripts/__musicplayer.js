var mp = (function() {

  //
  // Variables
  //
  var w = $(window),
      playlist,
      playlistID,
      playlistIndex,
      curPlaylistUrl,
      curSection,
      curSongInfo,
      curSong,
      maxIndex,
      isPlaying = false,
      dragging_position = false,
      dragging_percent,
      curPage,
      curPlayingPage,
      playingPage = '',
      playingPageNum = 1,
      smReady = false,
      delayStart = false,
      volume = $.cookie('volume') || ($.cookie('volume', 100) && 100),
      time = 0,
      autoPlay = false,
      hasMoved = false,
      timerInterval,
      NORMAL = 0,
      REPEAT = 1,
      SHUFFLE = 2,
      playModes = {0: 'normal', 1: 'repeat', 2: 'shuffle'},
      playMode = $.cookie('playmode'),
      failures = 0,
      playTimeout,
      usedKeyboard = false,
      listenUrl,
      startedAt,
      isLive,
      played = [],
      justStarted,
      justStartedTimeout,
      playCount = parseInt($.cookie('plays') || ($.cookie('plays', 0) && 0), 10),
      curSongLoaded = false,
      soundcloudKey = $('body').attr('data-soundcloud-key'),
      isLoaded = false;

  // Playmode
  playMode = playMode || NORMAL;

  // Elements
  var pl = {
    bar: $('#player-progress-bar'),
    loaded: $('#player-progress-loaded'),
    position: $('#player-progress-position'),
    handle: $('#player-progress-grabber'),
    player: $('#player'),
    song: $('#player-song'),
    meta: $('#player-meta'),
    play: $('#player-play'),
    volume: $('#player-volume'),
    timer: $('#player-timer')
  };

  // Soundmanager
  soundManager.url = '/swfs/soundmanager2_debug.swf';
  soundManager.useFlashBlock = true;
  soundManager.debugMode = false;
  soundManager.useHTML5Audio = true;
  soundManager.preferFlash = false;
  soundManager.onready(function() {
    smReady = true;
    if (delayStart) player.play();
    if (soundManager.supported()) {
      pl.handle.bind('mousedown', player.startDrag);
      $('body').bind('mouseup.dragger', player.endDrag);
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
      if (typeof section == 'string' || typeof section == 'object') section = $(section);
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

    setPlayingPage: function() {
      playingPage = curPage.replace(/\/?p-[0-9]+\/?.*/, '');
      playingPageNum = parseInt(playlist.id.split('-')[1], 10);

      if (playingPageNum > 1) {
        playingPage = playingPage + '/p-' + playingPageNum;
      }
    },

    // Load playlist
    load: function load() {
      fn.log('loading', curSection);
      if (!curSection) curSection = $('.playlist:visible section:first');
      if (curSection.length) {
        playlistIndex = curSection.data('index');
        playlistID = curSection.data('station');

        // Checking to see if first time loaded, or if loading new playlist
        if (typeof playlist === 'undefined' || playlist.id != playlistID) {
          if (playlist) fn.log(playlist.id, playlistID);
          fn.log('loading', playlistIndex, playlistID);

          // Get new playlist
          var el = $('#playlist-' + playlistID);
          playlist = el.data('playlist');
          playlist.id = playlistID;
          broadcasts = el.next('script');
          fn.log('broadcasts', broadcasts);

          // Remember this page
          player.setPlayingPage();

          // Add indices
          for (var i = 0; i < playlist.songs.length; i++) {
            playlist.songs[i].index = i;
          }

          maxIndex = i;
          curPlaylistUrl = playingPage;
          played = [];

          // Callback
          w.trigger('mp:load', player.state());
          fn.log('loaded',playlist,playlistID);
          return true;
        }
      }
    },

    playCompressedFile: function playCompressedFile() {
      this.playUrl(curSongInfo.id, '/play/' + curSongInfo.id + '?token=' + curSongInfo.token + '&key=' + (new Date()).getTime());
    },

    // Play song
    play: function play() {
      var self = this;
      self.setCurSection('playing');

      if (!smReady) {
        delayStart = true;
      }
      else {
        // Load
        if (!playlist) self.load();
        fn.log('Playlist...', playlist, 'Index...', playlistIndex, 'Songs length...', playlist.songs.length);

        if (playlist && playlistIndex < playlist.songs.length) {
          curSongLoaded = false;

          // Load song
          curSongInfo = playlist.songs[playlistIndex];
          w.trigger('mp:play', player.state());

          player.playCurSong();

          if (!curSection) {
            var foundSection = $('#playlist-' + playlist.id + ' #song-' + curSongInfo.id);
            if (foundSection.length) curSection = foundSection;
          }

          return true;
        }
        else {
          fn.log('playing fail');
          self.refresh();
          return false;
        }
      }
    },

    playCurSong: function() {
      var self = this;

      // Determine soundcloud
      if (curSongInfo.sc_id !== '') {
        $.ajax({
          type: 'get',
          url: 'http://api.soundcloud.com/tracks/' + curSongInfo.sc_id + '.json?client_id=' + soundcloudKey,
          success: function(data) {
            if (data) {
              if (data.errors) {
                self.setSoundCloudFailed();
                self.playCompressedFile()
              } else {
                self.playUrl(curSongInfo.id, data.stream_url + "?client_id=" + soundcloudKey);
                fn.log(data);
                w.trigger('mp:play:soundcloud', [player.state(), data] );
              }
            }
            else {
              self.setSoundCloudFailed();
              self.playCompressedFile();
            }
          },
          error: function() {
            // Fallback to our file if soundcloud deleted it
            // TODO report this and change in database
            self.setSoundCloudFailed();
            self.playCompressedFile();
          }
        });
      }
      else {
        self.playCompressedFile();
      }
    },

    playUrl: function(id, url) {
      curSong = soundManager.createSound({
        id: id,
        url: url,
        onplay: events.play,
        onstop: events.stop,
        onpause: events.pause,
        onresume: events.resume,
        onfinish: events.finish,
        whileloading: events.whileloading,
        whileplaying: events.whileplaying,
        onload: events.onload,
        volume: volume,
        stream: (startedAt ? false : true)
      });

      clearTimeout(playTimeout);
      playTimeout = setTimeout(function() {
        fn.log('Song at index', playlistIndex, 'info', curSongInfo, 'url', url);

        if (playlistIndex) played.push(curSongInfo);
        player.resetJustStarted();

        // If we have a time set
        if (time > 0) {
          curSong.setPosition(time * 1000);
          time = 0;
        }

        // Play
        if (curSong) curSong.play();
      }, 300);
    },

    playSong: function playSong(index) {
      fn.log("play song at", index);
      if (playlist) {
        playlistIndex = index;
        this.stop();
        this.play();
      }
    },

    stop: function stop() {
      clearTimeout(playTimeout);
      if (isPlaying && curSong) {
        curSong.stop();
        soundManager.stopAll();
      }
    },

    pause: function pause() {
      clearTimeout(playTimeout);
      if (isPlaying) {
        curSong.pause();
      }
    },

    replay: function() {
      this.stop();
      this.play();
    },

    rewind: function() {
      this.resetJustStarted();
      curSong.setPosition(0);
    },

    toggle: function toggle() {
      if (isPlaying) this.pause();
      else this.play();
    },

    next: function next() {
      if (isLive) return;

      clearTimeout(playTimeout);
      if (playMode == SHUFFLE) {
        return this.shuffleNext();
      }

      // Next section, or next song, or next playlist
      var nextSection = curSection && curSection.nextAll('section:first');
      if (nextSection && nextSection.length)
        return this.playSection(nextSection);
      else if (curSongInfo.index + 1 < maxIndex)
        this.playSong(curSongInfo.index + 1);
      else
        return this.toPlaylist('next');
    },

    shuffleNext: function() {
      var nextSections = $('.playlist section:not(.played)'),
          numNext = nextSections.length;

      if (numNext > 0) {
        var nextIndex = Math.floor(Math.random() * numNext);
        this.playSection(nextSections[nextIndex]);
      } else {
        fn.log('End of playlist');
      }
    },

    prev: function prev() {
      fn.log('isLive', isLive, 'justStarted', justStarted, 'playmode', playMode, 'index', curSongInfo.index);
      if (isLive) return;
      if (!justStarted) return this.rewind();

      if (playMode == SHUFFLE && played.length > 1) {
        played.pop();
        var prevSection = $('#song-' + played.pop().id);
        fn.log('prev shuffle', prevSection);
        if (prevSection.length) return this.playSection(prevSection);
      }

      var prevSection = curSection.prevAll('section:first');
      fn.log('prevSection', prevSection);
      if (prevSection.length)
        return this.playSection(prevSection);
      else if (curSongInfo.index > 0)
        return this.playSong(curSongInfo.index - 1);
      else
        return this.toPlaylist('prev');
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
        if (fw) {
          var next = $('#' + $('.playlist-song section.active').parent().attr('id')).next().next();
          if (next.length) this.playSection(next);
        }

        curSection = null;
        w.trigger('mp:playlist:end', player.state());
        return false;
      }
    },

    resetJustStarted: function() {
      fn.log('reset just started');
      clearTimeout(justStartedTimeout);
      justStarted = true;
      // justStartedTimeout = setTimeout(function() {
      //   justStarted = false;
      // }, 1000);
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
        'playing':  ['paused', 'active playing played listened-to'],
        'paused':   ['playing', 'paused'],
        'inactive': ['paused playing active', '']
      }

      if (curSection && curSection.length) {
        if (curSongInfo) fn.log('setting song ' + curSongInfo.name + ' to ' + status);
        curSection.removeClass(statuses[status][0]).addClass(statuses[status][1]);
      }
    },

    toggleVolume: function toggleVolume() {
      if (volume == 100) {
        pl.volume.removeClass('icon-volume-on');
        pl.volume.addClass('icon-volume-off');
        volume = 0;
        $.cookie('volume', volume);
        this.setVolume();
      } else {
        pl.volume.addClass('icon-volume-on');
        pl.volume.removeClass('icon-volume-off');
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
      $('body').unbind('mouseup.dragger').bind('mouseup.dragger', player.endDrag);
    },

    endDrag: function endDrag(e) {
      if (dragging_position) {
        dragging_position = false;
        pl.handle.unbind('mousemove');
        $('body').unbind('mouseup.dragger');
        player.followDrag(e);
        player.updateProgress();
      }
    },

    followDrag: function followDrag(e) {
      var e      = e ? e : window.event,
          x      = parseInt(e.clientX),
          offset = pl.handle.offset().left,
          width  = pl.bar.width(),
          newPos = Math.round(((x - offset) / width) * 100);

      // fn.log(e,x,offset,width,newPos);
      dragging_percent = newPos;
      if (dragging_percent >= 100 || dragging_percent <= 0) player.endDrag();
      else player.updateProgress();
    },

    updateProgress: function updateProgress() {
      if (!isLoaded) return false;
      var duration     = curSong.durationEstimate || curSong.duration || 0,
          milliseconds = Math.round(duration * (dragging_percent / 100));
      // fn.log(dragging_percent/100, duration, milliseconds);
      pl.position.attr('width', dragging_percent + '%');
      curSong.setPosition(milliseconds);
      this.startTimer();
    },

    startTimer: function startTimer() {
      clearInterval(timerInterval);
      timerInterval = setInterval(function() {
        var position = curSong.position / 1000,
            seconds = fn.pad(Math.floor(position) % 60, 2),
            minutes = Math.floor(position / 60);

        pl.timer.html(minutes + ":" + seconds);
      }, 1000);
    },

    state: function() {
      return mp;
    },

    setSoundCloudFailed: function() {
      fn.log('soundcloud failed');
    }
  };


  //
  // Events
  //
  var events = {
    play: function play() {
      isPlaying = true;
      player.setCurSection('playing');
      player.refresh();
      player.startTimer();
      usedKeyboard = false;
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
      fn.log('finished', curSong);
      if (playMode == REPEAT) player.replay();
      else player.next();
    },

    whileloading: function whileloading() {
      if (!curSongLoaded) {
        pl.loaded.css('width',(Math.round((this.bytesLoaded/this.bytesTotal)*100))+'%');

        // Waiting to fast forward to right position
        if (startedAt) {
          var now = Math.ceil((new Date()).getTime() / 1000),
              seconds_past = now - parseInt(startedAt, 10);

              fn.log(startedAt, seconds_past, this.duration / 1000)
          if (this.duration / 1000 >= seconds_past) {
            this.setPosition(seconds_past * 1000);
            this.play();
            startedAt = null;
          }
        }
      }
    },

    whileplaying: function whileplaying() {
      //updateTime.apply(this);
      pl.position.css('width',(Math.round(this.position/this.durationEstimate*1000)/10)+'%');
    },

    onload: function onload(success) {
      isLoaded = true;
      curSongLoaded = true;
      pl.loaded.css('width','100%');

      if (success) {
        curPlayingPage = curSection ? parseInt(curSection.parents('.playlist').data('page'), 10) : curPlayingPage;
        playCount++;

        w.trigger('mp:played', player.state());

        $.cookie('plays', playCount);
        $('body').addClass('loaded');

        // Scrobbling
        $.ajax({
          type: 'POST',
          url: '/listens',
          data: {
            listen: {
              song_id: curSongInfo.id,
              user_id: $('#current_user').data('id'),
              url: playingPage,
              seconds: curSongInfo.seconds
            }
          },
          success: function playSuccess(data) {
            listenUrl = data;
            w.trigger('mp:got:listen', player.state());
          },
          dataType: 'html'
        });
      }
      // Failure
      else {
        fn.log('failure', success);
        failures++;
        $.post('/songs/' + curSongInfo.id, { failing: true, songInfo: curSongInfo });

        // Retry normal file if soundcloud fail
        if (curSongInfo.sc_id !== '') {
          curSongInfo.sc_id = '';
          player.playCurSong();
        }
        else if (curSection) curSection.addClass('failed');

        if (failures < 5) player.next();
      }
    }
  };


  //
  // API
  //

  return {

    updatePage: function updatePage(url) {
      fn.log("Updating page url", url);
      curPage = url;
    },

    setPage: function setPage(url, callback) {
      curPage = url;
      failures = 0;
      fn.log('on playing page?', this.isOnPlayingPage());
      if (this.isOnPlayingPage()) {
        // If we return to the page we started playing from, re-activate current song
        curSection = $('#song-' + curSongInfo.id);
        fn.log('on playing page again, section', curSection, 'isplaying', isPlaying);
        if (curSection && isPlaying) {
          player.setCurSection('playing');
          fn.log(curSection);
          if (callback) callback(curSection);
        }
      }
      else {
        curSection = null;

        if (autoPlay) {
          fn.log('AUTO PLAY');
          player.playSection($('.playlist:first section:first'));
          autoPlay = false;
        }
      }

      return curSection;
    },

    getPage: function () {
      return curPage;
    },

    getCurPlayingPage: function() {
      return curPlayingPage;
    },

    getListenUrl: function() {
      return listenUrl;
    },

    isOnPlayingPage: function isOnPlayingPage(url) {
      var page = url || playingPage;
      if (curPage == page) return true;

      if (page) {
        var playPageBase = page.replace(/\/p-[^\/]+$/,''),
            curPageBase = curPage.replace(/\/p-[^\/]+$/,'');

        return playPageBase == curPageBase && curSongInfo && $('#song-' + curSongInfo.id).length;
      }

      return false;
    },

    playingPageNum: function() {
      return playingPageNum;
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

    isLoaded: function() {
      return isLoaded;
    },

    toggleVolume: function() {
      player.toggleVolume();
    },

    volume: function() {
      return volume;
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

    setCurSection: function(section) {
      curSection = section;
    },

    load: function() {
      player.load();
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
    },

    curPlaylistUrl: function() {
      return curPlaylistUrl;
    },

    nextPlayMode: function() {
      return this.setPlayMode(++playMode % 3);
    },

    setPlayMode: function(mode) {
      playMode = mode;
      $.cookie('playmode', playMode);
      return playModes[playMode];
    },

    playMode: function() {
      return playModes[playMode];
    },

    usedKeyboard: function() {
      return usedKeyboard;
    },

    setKeyboardUsed: function() {
      usedKeyboard = true;
    },

    startedAt: function(timestamp) {
      startedAt = timestamp;
    },

    setLive: function(val) {
      isLive = val;
    },

    isLive: function() {
      return isLive;
    },

    getPlayed: function() {
      return played;
    },

    plays: function() {
      return playCount;
    },

    played: function() {
      return played;
    }
  };

}(window, mp));