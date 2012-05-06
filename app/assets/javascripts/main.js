// Variables
var w = $(window),
    highlightedSong,
    highlightTimeout,
    songOffsets = [],
    playlistOffset,
    songSections,
    tipsyClearTimeout,
    bar = $('#bar'),
    debug = false;

function highlightSong() {
  var windowOffset = w.scrollTop()+70,
      cur = highlightedSong,
      i = 0;

  for (; i<songOffsets.length; i++) {
    if (songOffsets[i] > windowOffset) break;
  }

  highlightedSong = songSections.eq(i).addClass('highlight');
  if (cur && cur.attr('id') != highlightedSong.attr('id'))
    cur.removeClass('highlight');
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
var urlParams = {},
    updateParams = (function () {
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

$('img').on('error', function(){ $(this).attr('src','/images/default_medium.jpg'); });

//
// Document.ready
//

$(function() {
  // Fire initial page load
  page.start();
  page.end();

  // html5 pushState
  $("a:not(.control)").pjax({
    container: '#body',
    timeout: 6000
  });

  // Disabled links modal windows
  $('a.disabled').on('click', function(e) {
    e.preventDefault();
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

  // Bar buttons
  $('#bar-top').html('{').click(function(e) {
    e.preventDefault();
    $('html,body').animate({scrollTop:0}, 200);
  });

  // Tooltips
  $('.tip-n:not(.disabled)').tipsy({gravity: 'n', offset: 5, live: true});
  $('.tip:not(.disabled)').tipsy({gravity: 's', offset: 5, live: true});
  w.scroll(function(){
    // Removes on scroll
    clearTimeout(tipsyClearTimeout);
    tipsyClearTimeout = setTimeout(function(){ $('.tipsy').remove() },100);
  });

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
      window.location = '/'+data.url;
    }
  });

  // Dropdown menu
  $('#nav-username').click(function(e) {
    e.preventDefault();
    var nav = $(this).next('.nav-dropdown');

    if (nav.is('.open')) nav.removeClass('open');
    else nav.addClass('open');
  });

  // Player controls
  mpClick('#player-play', 'toggle');
  mpClick('#player-next', 'next');
  mpClick('#player-prev', 'prev');
  mpClick('#player-volume', 'volumeToggle');

  // Play from playlist
  $('#player-playlist a').live('click',function(e) {
    e.preventDefault();
    fn.log('playing from playlist');
    var song    = $(this),
        section = $(song.attr('href')),
        index   = song.data('index');

    if (section.length) mp.playSection(section);
    else mp.playSong(index);
  });

  // Window scroll highlights songs
  w.scroll(function() {
    clearTimeout(highlightTimeout);
    highlightTimeout = setTimeout(highlightSong,25);
  });

  // Playlist bar hover
  var progressBar = $('#player-progress-bar'),
      progressHoverTimeout;
  progressBar.hover(function() {
    progressHoverTimeout = setTimeout(function() { progressBar.addClass('hover'); }, 300);
  }, function() {
    clearTimeout(progressHoverTimeout);
    progressBar.removeClass('hover');
  });

  // Popups
  $('.popup').click(function(e){
    e.preventDefault();
    var link = $(this),
        dimensions = link.data('dimensions').split(',');
    window.open(link.attr('href'),link.attr('title'),'status=0,toolbar=0,location=0,height='+dimensions[0]+',width='+dimensions[1]);
  })

  // Dialog
  setTimeout(function() {
    $('#dialog').animate({opacity:'0'},500,function() {
      $(this).hide();
    });
  },1000);


  // Debug
  $('div,li,section').hover(function() {
    var d = $(this).children('.debug_dump');
    if (d.length) {
      $('#debug_dump').html(d.html());
    }
  });

  $('#debug').click(function(e) {
    e.preventDefault();
    if (debug) {
      $('#debug_dump').removeClass('visible');
      debug = false;
    }
    else {
      $('#debug_dump').addClass('visible');
      debug = true;
    }
  })
});