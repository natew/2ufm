var playlist;
var curSongIndex = 0;
var curSongInfo;
var curSong;
var isPlaying =  false;

var dragging_position = false;
var dragging_x;

soundManager.url = '/swfs/soundmanager2_debug.swf';
soundManager.flashVersion = 9; // optional: shiny features (default = 8)
soundManager.useFlashBlock = false; // optionally, enable when you're ready to dive in

soundManager.onready(function() {
  if(soundManager.supported()) {
    $('#player-progress-loaded').bind('mousedown', player_start_drag);
    $('#player-progress-position').bind('mousedown', player_start_drag);
    $('#player-progress-loaded').bind('mouseup', player_end_drag);
    $('#player-progress-position').bind('mouseup', player_end_drag);
  } else {
    // not supported
  }
});

function load_playlist() {
  playlist = jQuery.parseJSON($('#playlist').html());
  curSong = playlist.tracks[0];
}

function play(index) {
  // Song info
  curSongInfo = playlist.tracks[index];
  curSongIndex = index;
  
  // Update universal player
  $('#player').addClass('playing');
  $('#player .player-title').html(curSongInfo.artist + ' - ' + curSongInfo.name);
  
  // Update page player
  

  // Load song
  curSong = soundManager.createSound(curSongInfo);
  curSong.play();
  isPlaying = true;
}

function stop() {
  curSong.stop();
  curSongIndex = 0;
  isPlaying = false;
}

$(function() {
  // Get playlist for this page
  load_playlist();
  
  // Player controls
  // PLAY
  $('#player-controls a.play').click(function() {
    var $this = $(this);
    var $player = $('#player');
    if ($player.is('.playing')) {
      // pause
      $player.removeClass('playing');
      stop();
    } else {
      // play
    }
    return false;
  });
  
  // NEXT
  $('#player-controls a.next').click(function() {
    play_next_song();
    return false;
  });

  $('a.play-song').click(function() {
    var $this = $(this);
    if ($this.is('.playing')) {
      // pause
      $this.removeClass('playing');
      $(this).parent().parent().parent('section').removeClass('active');
      pause();
    } else {
      // play
      $this.addClass('playing');
      $(this).parent().parent().parent('section').addClass('active');
      play(parseInt($this.attr('rel')));
    }
    return false;
  });
});

function play_next_song() {
  curSongIndex++;
  play(curSongIndex);
}


window.player_start_drag = function(event) {
  if (!event) var event = window.event;
  element = event.target || event.srcElement;
  
  if (element.id.match(/progress/)) {
    dragging_position = true;
    $(window).unbind('mousemove').bind('mousemove', player_follow_drag);
    $(window).unbind('mouseup').bind('mouseup', player_end_drag);
  }
  
  return false;
}

window.player_end_drag = function(event) {
  if (!event) var event = window.event; // IE Fix
  element = event.target || event.srcElement;

  dragging_position = false;
  $(window).unbind('mousemove');
  $(window).unbind('mouseup');

  if (element.id.match(/progress/)) {
    player_update_progress(event, element);
  }

  return false;
}

window.player_follow_drag = function(event) {
  if (!event) var event = window.event;
  element = event.target || event.srcElement;

  var x = parseInt(event.clientX);
  var pos = curSong.position;

  $('#player-progress-position').width((Math.round( player_position / player_duration * 100 * 100) / 100 ) + '%')

  sm_update_progress(evt, t_elt);
  if(player_position >= player_duration) sm_end_drag();
}