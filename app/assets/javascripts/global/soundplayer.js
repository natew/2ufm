var playlist = null;

var curSection = null;
var curSongInfo;
var curSong;

var isPlaying =  false;

var dragging_position = false;
var dragging_x;

soundManager.url = '/swfs/soundmanager2_debug.swf';
soundManager.flashVersion = 9; // optional: shiny features (default = 8)
soundManager.useFlashBlock = false; // optionally, enable when you're ready to dive in
soundManager.debugMode = false;

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
  $('a.play-song').click(function() {
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
  
  if (!playlist) load_playlist();
  if (!curSection) curSection = $('#song-playlist section:first');
  
  // Update section
  $('#song-playlist section').removeClass('playing');
  curSection.addClass('playing');
  
  // Get song
  playlistIndex = parseInt(curSection.attr('rel'));
  curSongInfo = playlist.tracks[playlistIndex];
  
  // Update universal player
  $('#player').addClass('playing');
  $('#player .player-title').html(curSongInfo.artist + ' - ' + curSongInfo.name);

  // Load song
  curSong = soundManager.createSound(curSongInfo);
  curSong.play();
  isPlaying = true;
}

function player_pause() {
  curSong.pause();
  isPlaying = false;
}

function player_stop() {
  $('#song-playlist section').removeClass('playing');
  curSection.removeClass('playing');
  curSection = null;
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