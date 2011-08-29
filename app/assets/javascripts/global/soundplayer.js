var playlist = null;

var curSection = null;
var curSongInfo;
var curSong;

var isPlaying =  false;

var dragging_position = false;
var dragging_x;

var useThrottling = false;
var lastWPExec = new Date();
var lastWLExec = new Date();

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

$(function() {  
  // Player controls
  // PLAY
  $('#player-controls a.play').click(function() {
    var $player = $('#player');
    if ($player.is('.playing')) {  // pause
      $player.removeClass('playing');
      player_stop();
    } else {  // play
      $player.addClass('playing');
      player_play();
    }
    return false;
  });
  
  // NEXT
  $('#player-controls a.next').click(function() {
    player_next();
    return false;
  });
  
  // PREV
  $('#player-controls a.prev').click(function() {
    player_prev();
    return false;
  });
  

  // Play from song
  $('a.play-song').live('click',function() {
    var $section = $(this).parent().parent().parent('section');
    if ($section.is('.playing')) {
      curSection = null;
      player_stop();
    } else {
      curSection = $section;
      player_play();
    }
    return false;
  });
});

function load_playlist() {
  var $playlist = $('#playlist');
  if ($playlist) {
    playlist = jQuery.parseJSON($playlist.html());
  }
}

function player_play() {
  var playlistIndex = 0;

  // Get playlist and song info
  if (!playlist) load_playlist();
  if (!curSection) curSection = $('.song-playlist section:first');
  playlistIndex = parseInt(curSection.attr('rel'));
  curSongInfo = playlist.tracks[playlistIndex];

  // Load song
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
  
  // Play :)
  curSong.play();
}

function player_pause() {
  curSong.pause();
  isPlaying = false;
}

function player_stop() {
  curSong.stop();
  isPlaying = false;
}

function player_next() {
  curSong.stop();
  curSection = curSection.next();
  player_play();
}

function player_prev() {
  curSong.stop();
  curSection = curSection.prev();
  player_play();
}


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

var events = {
  play: function() {    
    isPlaying = true;
    
    // Update section
    $('.song-playlist section').removeClass('playing');
    curSection.addClass('playing');
    
    // Update universal player
    $('#player').addClass('playing');
    $('#player-song').html(curSongInfo.name);
    $('#player-artist').html(curSongInfo.artist);
  },
  
  stop: function() {
    $('.song-playlist section').removeClass('playing');
    if (curSection) curSection.removeClass('playing');
    curSection = null;
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
    if (!useThrottling) {
      doWork.apply(this);
    } else {
      var d = new Date();
      if (d && d-lastWLExec>30 || this.bytesLoaded === this.bytesTotal) {
        doWork.apply(this);
        lastWLExec = d;
      }
    }
  },
  
  whileplaying: function() {
    var d = null;
    if (!useThrottling) {
      updateTime.apply(this);
      $('#player-progress-position').css('width',(((this.position/this.duration)*100)+'%'));
    } else {
      d = new Date();
      if (d-lastWPExec>30) {
        updateTime.apply(this);
        $('#player-progress-position').css('width',(((this.position/this.duration)*100)+'%'));
        lastWPExec = d;
      }
    }
  },
  
  metadata: function() {
  
  },
  
  onload: function() {
  
  }
};

function updateTime() {
  //var str = self.strings.timing.replace('%s1',self.getTime(this.position,true));
  //str = str.replace('%s2',self.getTime(self.getDurationEstimate(this),true));
  //this._data.oTiming.innerHTML = str;
};