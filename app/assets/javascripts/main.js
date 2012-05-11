// Variables
var w = $(window),
    highlightedSong,
    highlightTimeout,
    songOffsets = [],
    playlistOffset,
    songSections = [],
    tipsyClearTimeout,
    bar = $('#bar'),
    debug = false,
    loggedIn = $('#nav-username').length > 0,
    modalShown = false,
    navOpen,
    loading_scroll = false,
    doneScrolling = false,
    scrollPage = 1,
    totalPages = 0;

function highlightSong() {
  var windowOffset = w.scrollTop()+70,
      cur = highlightedSong;

  for (var page = totalPages-1; page>0; page--) {
    if (page >= 1 && songOffsets[page-1][songOffsets[page-1].length-1] < windowOffset) {
      fn.log('breaking at page', page, songOffsets[page][0], windowOffset);
      break;
    }
  }

  for (var i = 0; i<songOffsets[page].length; i++) {
    if (songOffsets[page][i] > windowOffset) {
      // fn.log('breaking at song',i,songOffsets[page][i], windowOffset);
      break;
    }
  }

  highlightedSong = songSections[page].eq(i).addClass('highlight');
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

function resetOffsets() {
  totalPages = 0;
  songOffsets = [];
}

// Calculates offsets given sections
function addOffsets(sections) {
  var page = totalPages;
  fn.log('adding offsets from page', page);
  songSections[page] = sections;
  songOffsets[page] = new Array(sections.length);
  sections.each(function(index) {
    songOffsets[page][index] = $(this).offset().top;
  });
  totalPages++;
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
    var hash = window.location.hash.split('-');
    if (hash[0] == 'song') {
      // TODO time
      mp.playSection($('.playlist section:first'), time[0]*60 + time[1]);
    }
    else if (hash[0] == 'page') {
      // TODO pagination with hash
    }
  }

  // Listen sharing
  updateParams.run();
  if (urlParams['play']) {
    var song = urlParams['song'];
    var time = urlParams['time'];
    var section = $('#song-'+song);
    mp.playSection(section);
  }

  // Tooltips
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
      window.location = '/'+data.url;
    }
  });

  function navDropdown(show, nav) {
    if (!nav) nav = $('.nav-dropdown:first');
    if (show) {
      nav.addClass('open');
      navOpen = true;
    } else {
      nav.removeClass('open');
      navOpen = false;
    }
  }

  // Player controls
  mpClick('#player-play', 'toggle');
  mpClick('#player-next', 'next');
  mpClick('#player-prev', 'prev');
  mpClick('#player-volume', 'volumeToggle');

  // Play from song
  $('.song-link').live('click', function songClick(e) {
    e.preventDefault();
    var section = $(this).parent();
    mp.playSection(section);
  });

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

  w.scroll(function() {
    // Window scroll highlights songs
    clearTimeout(highlightTimeout);
    highlightTimeout = setTimeout(highlightSong,50);

    // Removes on scroll
    clearTimeout(tipsyClearTimeout);
    tipsyClearTimeout = setTimeout(function(){ $('.tipsy').remove() },100);

    //Infinite scrolling
    if (!loading_scroll && !doneScrolling) {
      if (nearBottom()) {
        var id = $('.twothirds .playlist:visible:first').attr('id').split('-')[1];
        loading_scroll = true;
        scrollPage++;
        $.ajax({
          url: window.location.href,
          type: 'get',
          data: 'id='+id+'&page='+scrollPage,
          headers: {
            Accept: "text/page; charset=utf-8",
            "Content-Type": "text/page; charset=utf-8"
          },
          success: function(data) {
            loading_scroll = false;
            window.location.hash = 'page-'+scrollPage;
            $('.twothirds .playlist:last').after(data);
            addOffsets($('#playlist-'+id+'-'+scrollPage+' section'));
          },
          error: function() {
            doneScrolling = true;
          }
        })
      }
    }
  });

  // Determines if window is near bottom
  function nearBottom() {
    return w.scrollTop() >= ($(document).height() - $(window).height() - 100);
  }

  // Playlist bar hover
  var progressBar = $('#player-bottom'),
      progressHoverTimeout;
  progressBar.hover(function() {
    progressHoverTimeout = setTimeout(function() { progressBar.addClass('hover'); }, 300);
  }, function() {
    clearTimeout(progressHoverTimeout);
    progressBar.removeClass('hover');
  });

  // Modal
  function modal(selector) {
    var modal = $('#modal'),
        show = $('#overlay,#modal');
    if (modalShown) {
      show.removeClass('shown');
      modalShown = false;
    }
    else {
      modal.html($(selector).clone());
      show.addClass('shown');
      modalShown = true;
    }
  }

  $('#overlay').click(function() {
    modal();
  })

  $('body').click(function(e) {
    if (e.target.tagName == 'A') {
      if (e.target.className.match(/nav-control/)) {
        // Nav Dropdown
        e.preventDefault();
        var nav = $(e.target).next('.nav-dropdown');
        if (navOpen) navDropdown(false, nav);
        else navDropdown(true, nav);
      }
      else {
        navDropdown(false);
        if (!loggedIn && e.target.className.match(/broadcast-song/)) {
          // Not logged in modal
          modal('#new-user');
          return false;
        }
        else if (e.target.className.match(/modal/)) {
          // Modals
          modal(e.target.getAttribute('href'));
          return false;
        }
      }
    }
    // Not <a>
    else {
      if (navOpen) {
        navDropdown(false);
      }
    }
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

  //
  // Application integration
  //
  if (typeof macgap !== 'undefined') {
    document.addEventListener('play', function() {
      mp.toggle();
      showGrowlInfo();
    }, true);
    document.addEventListener('prev', function() {
      mp.prev();
      showGrowlInfo();
    }, true);
    document.addEventListener('next', function() {
      mp.next();
      showGrowlInfo();
    }, true);

    function showGrowlInfo() {
      var info = mp.curSongInfo();
      macgap.growl.notify({title: info.artist_name + " - " + info.name, content: 'Now playing'});
    }

    $('header h1 a').click(function() {
      window.location.reload();
      return false;
    });

    $('#get-app').remove();
  }

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