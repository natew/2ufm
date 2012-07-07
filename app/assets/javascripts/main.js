// Variables
var w = $(window),
    songOffsets = [],
    tipsyClearTimeout,
    infiniteScrollTimeout,
    debug = false,
    loggedIn = $('body.signed_in').length > 0,
    modalShown = false,
    navOpen,
    loadingPage = false,
    morePages = true,
    scrollPage = getPage(),
    totalPages = 0,
    enableInfiniteScroll = true,
    navItems = getNavItems(),
    navActive;

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
  // Fade in effect
  $('#overlay').removeClass('shown');
  setTimeout(function() { $('#overlay').removeClass('slow-fade') }, 500);

  // Fire initial page load
  page.start();
  page.end();

  // html5 pushState
  $("a:not(.control)").pjax({
    container: '#body',
    timeout: 6000
  });

  // Mac app download
  if (navigator.appVersion.indexOf("Mac")!=-1) {
    $('#sidebar .announce').addClass('ismac');
  }

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
      if (data.header == 'true') $item.addClass('unselectable header');
      return data.name;
    },
    onSelect: function (data, $item) {
      window.location = '/'+data.url;
    }
  });

  // Page load
  $('.next-page').live('click',function(e) {
    nextPage(this);
  })

  // Player controls
  mpClick('#player-play', 'toggle');
  mpClick('#player-next', 'next');
  mpClick('#player-prev', 'prev');
  mpClick('#player-volume', 'volumeToggle');

  // Play from song
  $('.song-link').live('click', function songClick(e) {
    e.preventDefault();
    var section = $(this.getAttribute('href'));
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

  // Page scroll functions
  w.scroll(function() {
    // Removes on scroll
    clearTimeout(tipsyClearTimeout);
    tipsyClearTimeout = setTimeout(function(){ $('.tipsy').remove() },100);

    // Automatic page loading
    if (!loadingPage) {
      clearTimeout(infiniteScrollTimeout);
      infiniteScrollTimeout = setTimeout(function() {
        if (nearBottom()) $('.next-page:visible').click();
      }, 20);
    }
  });

  // Determines if window is near bottom
  function nearBottom() {
    return w.scrollTop() >= ($(document).height() - $(window).height() - 400);
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

  // Close modal
  $('#overlay').click(function() { modal(false); });

  // Click binding
  $('body').click(function(e) {
    var parent = e.target;

    // Update last position (for loading spinner)
    lastPosition = [e.pageX, e.pageY];

    // Find A tag
    while (true) {
      if (parent.tagName == 'A' || parent.tagName == 'BODY') break;
      parent = parent.parentNode;
    }

    if (parent.tagName == 'A') {
      var el = $(parent);

      // Disabled
      if (el.is('.disabled')) {
        e.preventDefault();
        return false;
      }
      else {
        // Nav Dropdown
        if (el.is('.nav')) {
          navDropdown($(e.target));
          return false;
        }
        else {
          // Close any dropdowns
          navDropdown(false);

          // Not logged in
          if (!loggedIn) {
            if (el.is('.restricted')) {
              modal('#modal-user');
              return false;
            }
          }
          else {
            // Modals
            if (el.is('.modal')) {
              modal(e.target.getAttribute('href'));
              return false;
            }
          }
        }
      }
    }

    // Not a link click
    else {
      navDropdown(false);
    }
  });

  // Popups
  $('.popup').click(function(e){
    e.preventDefault();
    var link = $(this),
        dimensions = link.data('dimensions').split(',');
    window.open(link.attr('href'),link.attr('title'),'status=0,toolbar=0,location=0,height='+dimensions[0]+',width='+dimensions[1]);
  });

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
  }

  // Debug
  $('div,li,section').live('hover', function() {
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

// Bind selectors to callbacks
function mpClick(selector, callback) {
  $(selector).click(function(e) {
    e.preventDefault();
    fn.log(fn);
    mp[callback].call();
  });
}

function getNavItems() {
  var items = {};
  $('#navbar a').each(function() {
    var t = $(this);
    items[t.attr('href')] = t;
  });
  return items;
}

function setNavActive(page) {
  if (navActive) navActive.removeClass('active');
  var newNavActive = navItems[page];
  if (newNavActive) navActive = newNavActive.addClass('active');
}

// Reads URL parameters for ?page=X and returns X
function getPage() {
  var page = window.location.search.match(/page=([0-9]+)/);
  return page ? parseInt(page[1],10) : 1;
}

function updatePageURL(page) {
  var url = window.location.href.replace(/#.*/,''),
      page = 'page=' + page,
      page_regex = /page=[0-9]+/,
      hash = window.location.hash;

  // Replace old page
  if (url.match(page_regex)) {
    url = url.replace(page_regex, page);
  } else {
    url += url.match(/\?/) ? '&' + page : '?' + page;
  }

  url += hash;
  window.history.replaceState('',document.title,url);
}

function nextPage(link, callback) {
  var link = $(link).html('Loading').addClass('loading');
  // Infinite scrolling
  if (morePages) {
    var curPlaylist = $('.playlist:visible:last'),
        curPlaylistInfo = curPlaylist.attr('id').split('-'),
        id = curPlaylistInfo[1]
        page = curPlaylistInfo[2];

    loadingPage = true;
    scrollPage = parseInt(page,10) + 1;
    $.ajax({
      url: window.location.href,
      type: 'get',
      data: 'id=' + id + '&page=' + scrollPage,
      headers: {
        Accept: "text/page; charset=utf-8",
        "Content-Type": "text/page; charset=utf-8"
      },
      success: function(data) {
        var playlist = $('#playlist-' + id + '-' + scrollPage);
        link.remove();
        loadingPage = false;
        updatePageURL(scrollPage);
        curPlaylist.after(data);
        if (callback) callback.call(playlist);
      },
      error: function() {
        morePages = false;
      }
    })
  }
}

function navDropdown(nav, pad) {
  if (nav && nav.length) {
    var padding = pad ? pad : 20,
        target = nav.attr('href')[0] == '#' ? nav.attr('href') : nav.attr('data-target'),
        dropdown = $(target).removeClass('hidden'),
        top = nav.offset().top - $('body').scrollTop() + nav.height() + padding,
        left = Math.round(nav.offset().left + (nav.width()/2) - (dropdown.width()/2));

    // If the nav is not already open
    if (!(navOpen && navOpen[0] == dropdown[0])) {
      navOpen = dropdown.css({
        top: top,
        left: left
      }).addClass('open');

      return true;
    }
  }

  if (navOpen) navOpen.removeClass('open').addClass('hidden');
  navOpen = false;
}

// Modal
function modal(selector) {
  var modal = $('#modal'),
      show = $('#overlay,#modal');

  if (modalShown || selector === false) {
    show.removeClass('shown');
    modalShown = false;
  }
  else {
    modal.html($(selector).clone());
    show.addClass('shown');
    modalShown = true;
  }
}