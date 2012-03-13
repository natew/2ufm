var mp = (function() {
  //
  // Variables
  //
  var playlist = null,
      playlistID = null,
      playlistIndex = null,
      curSection = null,
      curSongInfo,
      curSong,
      isPlaying =  false,
      dragging_position = false,
      dragging_x,
      curPage,
      playingPage,
      smReady = false,
      delayStart = false,
      volume = 100,
      playlist_template = '';
  
  // Elements
  var pl = {
    bar: $('#player-progress-bar'),
    loaded: $('#player-progress-loaded'),
    position: $('#player-progress-position'),
    grabber: $('#player-progress-grabber'),
    player: $('#player'),
    song: $('#player-song'),
    play: $('#player-play'),
    invite: $('#invite'),
    volume: $('#player-volume'),
    playlist: $('#player-playlist')
  }

  // Soundmanager
  soundManager.url = '/swfs/soundmanager2_debug.swf';
  soundManager.flashVersion = 9; // optional: shiny features (default = 8)
  soundManager.useFlashBlock = false; // optionally, enable when you're ready to dive in
  soundManager.debugMode = true;
  //soundManager.useFastPolling = true;
  //soundManager.useHighPerformance = true;
  soundManager.useHTML5Audio = true;
  soundManager.preferFlash = false;
  soundManager.onready(function() {
    smReady = true;
    if (delayStart) player.play();
    if (soundManager.supported()) {
      pl.grabber.bind('mousedown', actions.startDrag);
      pl.grabber.bind('mouseup', actions.endDrag);
    } else {
      alert('Your browser does not support audio playback');
    }
  });
  
  
  //
  // Player functions
  //
  var player = {
    // Play a section
    playSection: function(section) {
      this.stop();
      curSection = section;
      console.log(curSection);
      this.load();
      this.play();
    },
    
    // Load playlist
    load: function() {
      if (!curSection) curSection = $('.playlist section:first');
      if (curSection) {
        console.log('loading playlist');
        playingPage = curPage;
        playlistIndex = curSection.data('index');
        playlistID = curSection.data('station');
        playlist   = $('#playlist-'+playlistID).data('playlist');

        $('#main-mid').addClass('loaded');
        playlist_template = Mustache.render(pl.playlist.html(),playlist);
        pl.playlist.html(playlist_template);
        pl.playlist.addClass('loaded');

        console.log('playlist loaded: '+playlistID);
      }
    },
    
    // Play song
    play: function() {
      if (!smReady) {
        delayStart = true;
      } else {
        // Load
        if (!playlist) this.load();

        if (playlist && playlistIndex < playlist.songs.length) {
          // Load song
          console.log('playing song at index: '+playlistIndex);
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

          console.log('song loaded: ' + curSong);
          curSong.play();
          return true;
        } else {
          curSection = null;
          this.refresh();
          return false;
        }
      }
    },
    
    stop: function() {
      if (isPlaying) {
        curSong.stop();
        soundManager.stopAll();
      }
    },
    
    pause: function() {
      if (isPlaying) {
        curSong.pause();
      }
    },
    
    toggle: function() {
      if (isPlaying) curSong.togglePause();
      else this.play();
    },
    
    next: function() {
      if (curSection) var next = curSection.next();
      this.stop();
      this.setCurSectionInactive();
      if (next) {
        curSection = next;
        this.setCurSectionActive();
      }
      playlistIndex++;
      this.play();
    },
    
    prev: function() {
      if (curSection) prev = curSection.prev();
      this.stop();
      this.setCurSectionInactive();
      if (prev) {
        curSection = prev;
        this.setCurSectionActive();
      }
      playlistIndex--;
      this.play();
    },
    
    refresh: function() {
      if (isPlaying) {
        var title = curSongInfo.artist + ' - ' + curSongInfo.name;
        pl.player.addClass('playing');
        pl.song.html(title);
        pl.play.html('5');
        // <title>
        icon = isPlaying ? '\u25BA' : '\u25FC';
        $('title').html(icon + ' ' + title);
      } else {
        pl.loaded.css('width', 0);
        pl.position.css('width', 0);
        pl.player.removeClass('playing');
        pl.play.html('4');
      }
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
        curSection.find('.play-song').html('4');
      }
    },

    updateProgress: function(percent) {
      pl.position.attr('width',percent+'%');
      console.log(curSong.durationEstimate, (percent/100), curSong.durationEstimate*(percent/100));
      curSong.setPosition(curSong.durationEstimate*(percent/100));
    },

    volumeToggle: function() {
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

    setVolume: function() {
      if (curSong) {
        curSong.setVolume(volume);
      }
    }
  }
  
  
  //
  // Actions
  //
  var actions = {
    click: function() {

    },

    startDrag: function(event) {
      if (!event) var event = window.event;
      element = event.target || event.srcElement;

      console.log('startdrag: ' + element.id)
      if (element.id.match(/grabber/)) {
        dragging_position = true;
        pl.grabber.unbind('mousemove').bind('mousemove', actions.followDrag);
        pl.grabber.unbind('mouseup').bind('mouseup', actions.endDrag);
      }

      return false;
    },

    endDrag: function(event) {
      if (!event) var event = window.event; // IE Fix
      element = event.target || event.srcElement;

      dragging_position = false;
      pl.grabber.unbind('mousemove');
      pl.grabber.unbind('mouseup');

      if (element.id.match(/grabber/)) {
        //player.updateProgress(event, element);
      }

      return false;
    },

    followDrag: function(event) {
      if (!event) var event = window.event;
      element = event.target || event.srcElement;

      var x      = parseInt(event.clientX),
          offset = pl.grabber.offset().left,
          width  = pl.grabber.width(),
          curPos = curSong.position,
          newPos = Math.round(((x - offset) / width) * 100);

      console.log('followdrag: ' + x + ' / ' + newPos + '%');

      player.updateProgress(newPos);
      if (newPos >= 100 || newPos <= 0) actions.endDrag();
    },
    
    
  };


  //
  // Events
  //
  var events = {
    play: function() {
      isPlaying = true;
      $('#player').addClass('loaded');
      player.setCurSectionActive();
      player.refresh();
      
      // Scrobbling
      $.ajax({
        type: 'POST',
        url: '/listens',
        data: { listen: { song_id: curSongInfo.id, user_id: $('#current_user').data('id'), url: curPage } },
        success: function(data) {
          pl.invite.attr('href','/l/'+data);
          pl.invite.addClass('show');
          other.clipboard();
        },
        dataType: 'html'
      });
    },

    stop: function() {
      isPlaying = false;
      player.setCurSectionInactive();
      curSection = null;
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
      player.setCurSectionInactive();
      player.next();
    },

    whileloading: function() {
      function doWork() {
        pl.loaded.css('width',(Math.round((this.bytesLoaded/this.bytesTotal)*100))+'%');
      }
      doWork.apply(this);
    },

    whileplaying: function() {
      //updateTime.apply(this);
      pl.position.css('width',(Math.round(this.position/this.durationEstimate*1000)/10)+'%');
    },

    metadata: function() {

    },

    onload: function(success) {
      if (!success) {
        var failedSection = curSection.addClass('failed');
        if (curPage == playingPage) player.next();
        $.post('songs/'+curSongInfo.id, { failing: 'true' }, function(data) {
          $('body').append(data);
          failedSection.remove();
        });
      }
    }
  };
  
  var other = {
    clipboard: function() {
      ZeroClipboard.setMoviePath('/swfs/ZeroClipboard.swf');
      var clip = new ZeroClipboard.Client();
      clip.setHandCursor(true);
      clip.glue('invite','player-shortcode');
      clip.setText(document.location.host+$('#invite').attr('href'));
      clip.addEventListener('mouseOver', function (client) {
      	$('#invite').trigger('mouseover').html('Copy link!');
      });
      clip.addEventListener('mouseOut', function (client) {
      	$('#invite').trigger('mouseout').html('&laquo; Invite friends!');
      });
      clip.addEventListener('complete', function(client, text) {
        var $invite = $('#invite');
        var html = $invite.html();
        $invite.html('Copied!')
        setTimeout(function() { $invite.html(html); }, 2000);
      });
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
      } else {
        curSection = null;
      }
      curPage = url;
    },
    
    toggle: function() {
      var played = player.toggle();
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

    volumeToggle: function() {
      player.volumeToggle();
    },
    
    playSection: function(section) {
      $('.playlist section:first-child').removeClass('show-play');
      player.playSection(section);
    },
    
    getSection: function() {
      return curSection;
    },
    
    getPlaylist: function() {
      return playlist;
    }
    
  }
  
}());