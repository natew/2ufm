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
  
  // Soundmanager
  soundManager.url = '/swfs/soundmanager2_debug.swf';
  soundManager.flashVersion = 9; // optional: shiny features (default = 8)
  soundManager.useFlashBlock = false; // optionally, enable when you're ready to dive in
  soundManager.debugMode = true;
  soundManager.useFastPolling = true;
  soundManager.useHighPerformance = true;
  soundManager.onready(function() {
    if(soundManager.supported()) {
      $('#player-progress-loaded').bind('mousedown', actions.start_drag);
      $('#player-progress-position').bind('mousedown', actions.start_drag);
      $('#player-progress-loaded').bind('mouseup', actions.end_drag);
      $('#player-progress-position').bind('mouseup', actions.end_drag);
    } else {
      // not supported
    }
  });
  
  
  //
  // Player functions
  //
  var player = {
    playSection: function(section) {
      this.stop();
      curSection = section;
      this.play();
    },
    
    // Load playlist
    load: function() {
      if (playlistID !== curSection.data('station')) {
        playlistID = curSection.data('station');
        playlist   = $('#playlist-'+playlistID).data('playlist');
      }
    },
    
    // Play song
    play: function() {
      // Get section
      if (!curSection) curSection = $('.playlist section:first');
      curSection.addClass('active');
      
      // Get playlist and index
      if (!playlist) this.load();
      playlistIndex = curSection.data('index');

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
    },
    
    stop: function() {
      if (isPlaying) {
        curSection.removeClass('active');
        curSection = null;
        curSong.stop();
      }
    },
    
    toggle: function() {
      if (isPlaying) this.stop();
      else this.play();
    },
    
    next: function() {
      this.stop();
      curSection = curSection.next();
      this.play();
    },
    
    prev: function() {
      this.stop();
      curSection = curSection.prev();
      this.play();
    },
    
    refresh: function() {
      // Head player
      var $player = $('#player');
      var $player_song = $('#player-song');
      var $player_artist = $('#player-artist');

      if (isPlaying) {
        $player.addClass('playing');
        $player_song.html(curSongInfo.name);
        $player_artist.html(curSongInfo.artist);
      } else {
        $player.removeClass('playing');
        $player_song.html('No Song');
        $player_artist.html(' ');
      }
      
      // <title>
      icon = isPlaying ? '\u25BA' : '\u25FC';
      $('title').html(icon + ' ' + curSongInfo.artist + ' - ' + curSongInfo.name);
    }
  }
  
  
  //
  // Actions
  //
  var actions = {
    drag: function(event) {
      if (!event) var event = window.event;
      element = event.target || event.srcElement;

      if (element.id.match(/progress/)) {
        dragging_position = true;
        $(window).unbind('mousemove').bind('mousemove', player_follow_drag);
        $(window).unbind('mouseup').bind('mouseup', player_end_drag);
      }

      return false;
    },

    end_drag: function(event) {
      if (!event) var event = window.event; // IE Fix
      element = event.target || event.srcElement;

      dragging_position = false;
      $(window).unbind('mousemove');
      $(window).unbind('mouseup');

      if (element.id.match(/progress/)) {
        player_update_progress(event, element);
      }

      return false;
    },

    follow_drag: function(event) {
      if (!event) var event = window.event;
      element = event.target || event.srcElement;

      var x = parseInt(event.clientX);
      var pos = curSong.position;

      $('#player-progress-loaded').width((Math.round( player_position / player_duration * 100 * 100) / 100 ) + '%')

      sm_update_progress(evt, t_elt);
      if(player_position >= player_duration) sm_end_drag();
    }
  };


  //
  // Events
  //
  var events = {
    play: function() {    
      isPlaying = true;

      // Update section
      $('.song-playlist section').removeClass('playing');
      curSection.addClass('playing');

      // Update player
      player.refresh();
    },

    stop: function() {
      isPlaying = false;

      $('.song-playlist section').removeClass('playing');
      if (curSection) curSection.removeClass('playing');
      curSection = null;

      // Update player
      player.refresh();
    },

    pause: function() {

    },

    resume: function() {

    },

    finish: function() {

    },

    whileloading: function() {
      function doWork() {
        $('#player-progress-loaded').css('width',(((this.bytesLoaded/this.bytesTotal)*100)+'%'));
      }
      doWork.apply(this);
    },

    whileplaying: function() {
      var d = null;
      updateTime.apply(this);
      $('#player-progress-position').css('width',(((this.position/this.duration)*100)+'%'));
    },

    metadata: function() {

    },

    onload: function() {

    }
  };  
  
  
  //
  // API
  //
  
  return {
    
    toggle: function() {
      player.toggle();
      return isPlaying;
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