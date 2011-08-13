playlist = null;
current_song = null;

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
  current_song = playlist.tracks[0];
}  
function play(index) {
  current_song = soundManager.createSound(playlist.tracks[index]);
  current_song.play();
}

$(function() {
  // Get playlist for this page
  load_playlist();

  $('a.play_song').click(function() {
    var song = $(this);
    $(this).parent().parent().parent('section').addClass('active');
    play(parseInt(song.attr('rel')));
    
    return false;
  });
});