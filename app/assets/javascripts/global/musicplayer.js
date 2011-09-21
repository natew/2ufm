var mp = (function() {
  //
  // Variables
  //
  var playlist = null;
  var playlistID = null;
  var playlistIndex = null;
  var curSection = null;
  var curSongInfo;
  var curSong;
  var isPlaying =  false;
  var dragging_position = false;
  var dragging_x;
  var curPage;
  var playingPage;
  
  // Elements
  var pl = {
    loaded: $('#player-progress-loaded'),
    progress: $('#player-progress-position'),
    player: $('#player'),
    song: $('#player-song'),
    play: $('#player-buttons .play')
  }

  // Soundmanager
  soundManager.url = '/swfs/soundmanager2_debug.swf';
  soundManager.flashVersion = 9; // optional: shiny features (default = 8)
  soundManager.useFlashBlock = false; // optionally, enable when you're ready to dive in
  soundManager.debugMode = true;
  soundManager.useFastPolling = true;
  soundManager.useHighPerformance = true;
  soundManager.useHTML5Audio = true;
  //soundManager.preferFlash = false;
  soundManager.onready(function() {
    if(soundManager.supported()) {
      pl.loaded.bind('mousedown', actions.startDrag);
      pl.progress.bind('mousedown', actions.startDrag);
      pl.loaded.bind('mouseup', actions.endDrag);
      pl.progress.bind('mouseup', actions.endDrag);
    } else {
      // not supported
    }
  });
  
  
  //
  // Player functions
  //
  var player = {
    // Play a section
    playSection: function(section) {
      this.stop();
      if (section.data('station') != playlistID) {
        this.load();
      }
      curSection = section;
      this.play();
    },
    
    // Load playlist
    load: function() {
      if (!curSection) curSection = $('.playlist section:first');
      if (curSection) {
        playingPage = curPage;
        playlistIndex = curSection.data('index');
        playlistID = curSection.data('station');
        playlist   = $('#playlist-'+playlistID).data('playlist');
      }
    },
    
    // Play song
    play: function() {
      // Load
      if (!playlist) this.load();

      if (playlist) {
        // Load song
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
          onload:events.onload
        });

        curSong.play();
      }
    },
    
    stop: function() {
      if (isPlaying) {
        curSong.stop();
      }
    },
    
    pause: function() {
      if (isPlaying) {
        curSong.pause();
      }
    },
    
    toggle: function() {
      if (curSong)
        curSong.togglePause();
      else
        this.play();
    },
    
    next: function() {
      if (curSection) {
        var next = curSection.next();
      }
      this.stop();
      curSection = next;
      playlistIndex++;
      this.play();
    },
    
    prev: function() {
      if (curSection) {
        prev = curSection.prev();
      }
      this.stop();
      curSection = prev;
      playlistIndex--;
      this.play();
    },
    
    refresh: function() {
      if (isPlaying) {
        pl.player.addClass('playing');
        pl.song.html(curSongInfo.artist + ' - ' + curSongInfo.name);
        pl.play.html('5');
      } else {
        pl.player.removeClass('playing');
        pl.play.html('4');
      }
      
      // <title>
      icon = isPlaying ? '\u25BA' : '\u25FC';
      $('title').html(icon + ' ' + curSongInfo.artist + ' - ' + curSongInfo.name);
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
        curSection.find('.play-song').html('9');
      }
    }
  }
  
  
  //
  // Actions
  //
  var actions = {
    startDrag: function(event) {
      if (!event) var event = window.event;
      element = event.target || event.srcElement;

      if (element.id.match(/progress/)) {
        dragging_position = true;
        $(window).unbind('mousemove').bind('mousemove', this.followDrag);
        $(window).unbind('mouseup').bind('mouseup', this.endDrag);
      }

      return false;
    },

    endDrag: function(event) {
      if (!event) var event = window.event; // IE Fix
      element = event.target || event.srcElement;

      dragging_position = false;
      $(window).unbind('mousemove');
      $(window).unbind('mouseup');

      if (element.id.match(/progress/)) {
        player.updateProgress(event, element);
      }

      return false;
    },

    followDrag: function(event) {
      if (!event) var event = window.event;
      element = event.target || event.srcElement;

      var x = parseInt(event.clientX);
      var pos = curSong.position;

      elements.loaded.width((Math.round( player_position / player_duration * 100 * 100) / 100 ) + '%')

      player.updateProgress(event, element);
      if (player_position >= player_duration) this.endDrag();
    },
    
    
  };


  //
  // Events
  //
  var events = {
    play: function() {
      isPlaying = true;
      player.setCurSectionActive();
      player.refresh();
    },

    stop: function() {
      isPlaying = false;
      player.setCurSectionInactive();
      curSection = null;

      // Update player
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
      player.next();
    },

    whileloading: function() {
      function doWork() {
        $('#player-progress-loaded').css('width',(Math.round((this.bytesLoaded/this.bytesTotal)*100))+'%');
      }
      doWork.apply(this);
    },

    whileplaying: function() {
      //updateTime.apply(this);
      $('#player-progress-position').css('width',(Math.round(this.position/this.durationEstimate*1000)/10)+'%');
    },

    metadata: function() {

    },

    onload: function(success) {
      if (!success) {
        var failedSection = curSection.addClass('failed');
        player.next();
        $.post('songs/'+curSongInfo.id, { failing: 'true' }, function(data) {
          $('body').append(data);
          failedSection.remove();
        });
      }
    }
  };  
  
  
  //
  // API
  //
  
  return {
    
    setPage: function(url) {
      if (curPage && curPage == playingPage) {
        // If we return to the page we started playing from, re-activate current song
        curSection = $('section#song-' + curSongInfo.id);
        player.setCurSectionActive();
      }
      curPage = url;
      curSection = null;
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
      player.next();
    },
    
    prev: function() {
      player.prev();
    },
    
    playSection: function(section) {
      player.playSection(section);
    },
    
    getSection: function() {
      return curSection;
    }
    
  }
  
}());