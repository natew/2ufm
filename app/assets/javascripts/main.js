// Variables
var commandPressed = false,
    $window        = $(window),
    playing,
    likeTimeout;

// Allow middle clicking for new tabs
var pressedDisable = function(e) {
  fn.log('command toggle');
  var command = e.metaKey || e.ctrlKey;
  if (command) commandPressed = true;
  else commandPressed = false;
}

// Sets bar to fixed
var setBarPosition = function() {
  if ($(window).scrollTop() > 44) $('#bar').addClass('fixed');
  else $('#bar').removeClass('fixed');
}

var keyShortcuts = function(e) {
  switch(e.keyCode) {
    // Left arrow
    case 37:
      mp.prev();
      break;
    // TODO ALL KEYBOARD SHORTCUTS
  }
}

// Bind selectors to callbacks
var mpClick = function(selector,callback) {
  $(selector).click(function(e) {
    e.preventDefault();
    fn.log(fn);
    mp[callback].call();
  });
}

// Read URL parameters
var urlParams = {};
var updateParams = (function () {
  function update() {
    var e,
        a = /\+/g,  // Regex for replacing addition symbol with a space
        r = /([^&=]+)=?([^&]*)/g,
        d = function (s) { return decodeURIComponent(s.replace(a, " ")); },
        q = window.location.search.substring(1);

    while (e = r.exec(q))
       urlParams[d(e[1])] = d(e[2]);
  }

  return {
    run: function() {
      update();
    }
  }
})();

// Image errors
$('img.cover-medium').on('error',function(){ $(this).attr('src', '/images/default_medium.jpg'); });
$('img.cover-small').on('error',function(){ $(this).attr('src', '/images/default_small.jpg'); });

//
// Document.ready
//
$(function() {
  // Fire initial page load
  page.start();
  page.end();

  // Keyboard shortucts
  $window.keydown(keyShortcuts);

  // Disable path.js when command button pressed (allow middle click)
  $window.keydown(pressedDisable).keyup(pressedDisable);
  $window.blur(pressedDisable); // Prevents bug where alt+tabbing always disabled

  // html5 pushState
  $("a:not(.control)").pjax('#body');

  // Disabled links modal windows
  $('a.disabled').on('click', function(e) {
    // Sign in modal
    return false;
  });

  // Hash tag to denote time in songs
  if (window.location.hash) {
    var time = window.location.hash.split(':');
    mp.playSection($('.playlist section:first'), time[0]*60 + time[1]);
  }

  // Listen sharing
  updateParams.run();
  if (urlParams['play']) {
    var song = urlParams['song'];
    var time = urlParams['time'];
    var section = $('#song-'+song);
    mp.playSection(section);
    $(window).scrollTop(section.offset().top-100);
  }

  // Scroll music player
  setBarPosition();
  $window.scroll(setBarPosition);

  // Bar buttons
  $('#bar-top').html('{').click(function(e) {
    e.preventDefault();
    $('html,body').animate({scrollTop:0}, 200);
  });

  $('#bar-bottom').html('}').toggle(function(e) {
    e.preventDefault();
    $(this).html('{').removeClass('tip-n').addClass('tip')
    $('#bar').addClass('bottom');
  }, function(e) {
    e.preventDefault();
    $(this).html('}').removeClass('tip').addClass('tip-n')
    $('#bar').removeClass('bottom');
  });

  // Tooltips
  $window.scroll(function(){ $('.tipsy').remove() }); // Fucking bugs
  $('.tip-n:not(.disabled)').tipsy({gravity: 'n', offset: 5, live: true});
  $('.tip:not(.disabled)').tipsy({gravity: 's', offset: 5, live: true});

  // Livesearch
  $('#query').marcoPolo({
    url: '/search',
    selectable: ':not(.unselectable)',
    formatItem: function (data, $item) {
      if (data.selectable == 'false') $item.addClass('unselectable');
      if (data.header == 'true') $item.addClass('unselectable').addClass('header');
      return data.name;
    },
    onSelect: function (data, $item) {
      window.location = data.url;
    }
  });

  // Dropdown menu
  $("body").bind("click", function(e) {
    $(".nav-dropdown").hide();
    $('.nav a').parent("div").removeClass("open").children("div.nav-dropdown").hide();
  });
  $("#nav-username").click(function(e) {
    var $target = $(this);
    var $parent = $target.parent("div");
    var $siblings = $parent.siblings("div.nav-dropdown");
    if ($parent.hasClass("open")) {
      $parent.removeClass("open");
      $siblings.hide();
    } else {
      $parent.addClass("open");
      $siblings.show();
    }
    return false;
  });

  // Player controls
  mpClick('#player-play', 'togglePlay');
  mpClick('#player-next', 'next');
  mpClick('#player-prev', 'prev');
  mpClick('#player-volume', 'volumeToggle');

  // Play from playlist
  $('#player-playlist a').on('click',function() {
    fn.log('playing from playlist');
    var $this    = $(this),
        $section = $($this.attr('href')),
        index    = $this.data('index');

    if ($section.length) {
      mp.playSection($section);
    } else {
      mp.playSong(index);
    }

    playing.removeClass('playing');
    playing = $('.song-'+index).addClass('playing');
  });

  // Play from song
  $('.play-song').on('click',function() {
    var $section = $(this).parent().parent('section');
    if ($section.is('.playing')) {
      mp.pause();
    } else {
      mp.playSection($section);
    }
    return false;
  });

  $('.broadcast-song span:not(.added)').on({
    mouseenter: function() {
      var $this = $(this);
      fn.log('hover');
      likeTimeout = window.setTimeout(function() {
        fn.log('running');
        if ($this.is(':hover')) {
          $('.tipsy-inner').html('Liked!');
          $this.addClass('added');
        }
      }, 600);
    },
    mouseleave: function() {
      fn.log('clearing');
      window.clearTimeout(likeTimeout);
    }
  });
});