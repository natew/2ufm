playlist = null;
curSongInfo = null;
curSong = null;
isPlaying =  false;

soundManager.url = '/swfs/soundmanager2_debug.swf';
soundManager.flashVersion = 9; // optional: shiny features (default = 8)
soundManager.useFlashBlock = false; // optionally, enable when you're ready to dive in

soundManager.onready(function() {
  if(soundManager.supported()) {
//        $('#player-progress-loading').bind('mousedown', sm_start_drag);
//        $('#player-progress-playing').bind('mousedown', sm_start_drag);
//        $('#player-volume-outer').bind('mousedown', sm_start_drag);
//        $('#player-progress-loading').bind('mouseup', sm_end_drag);
//        $('#player-progress-playing').bind('mouseup', sm_end_drag);
//        $('#player-volume-outer').bind('mouseup', sm_end_drag);
//        $('#player-volume-mute').bind('mouseup', sm_toggle_mute);

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
  
  // Update universal player
  $('#audio_player').addClass('playing');
  $('#audio_player .audio_title').html(curSongInfo.artist + ' - ' + curSongInfo.name);

  // Load song
  curSong = soundManager.createSound(curSongInfo);
  curSong.play();
  isPlaying = true;
}

function pause() {
  curSong.pause();
  isPlaying = false;
}

$(function() {
  // Get playlist for this page
  load_playlist();
  
  $('#audio_controls a.play').click(function() {
    var $this = $(this);
    if ($this.is('.playing')) {
      // pause
      $this.removeClass('playing');
      pause();
    } else {
      // play
    }
    return false;
  });

  $('a.play_song').click(function() {
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