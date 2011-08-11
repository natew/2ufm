soundManager.url = '/swfs/soundmanager2_debug.swf';
soundManager.flashVersion = 9; // optional: shiny features (default = 8)
soundManager.useFlashBlock = false; // optionally, enable when you're ready to dive in

soundManager.onready(function() {
    if(soundManager.supported()) {
        isReady = 1;
        $('#player-progress-loading').bind('mousedown', sm_start_drag);
        $('#player-progress-playing').bind('mousedown', sm_start_drag);
        $('#player-volume-outer').bind('mousedown', sm_start_drag);

        $('#player-progress-loading').bind('mouseup', sm_end_drag);
        $('#player-progress-playing').bind('mouseup', sm_end_drag);
        $('#player-volume-outer').bind('mouseup', sm_end_drag);

        $('#player-volume-mute').bind('mouseup', sm_toggle_mute);

    } else {
        // unsupported/error case :(
    }
});