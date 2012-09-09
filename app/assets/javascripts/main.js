// Variables
var w = $(window),
    songOffsets = [],
    tipsyClearTimeout,
    infiniteScrollTimeout,
    debug = false,
    isOnline = $('body.signed_in').length > 0,
    userId = $('body').data('user'),
    modalShown = false,
    navOpen,
    loadingPage = false,
    morePages = true,
    scrollPage = getPage(),
    totalPages = 0,
    enableInfiniteScroll = true,
    navItems = getNavItems(),
    navActive,
    pageEndOffsets = [],
    hideWelcome = $.cookie('hideWelcome'),
    volume = mp.volume(),
    shuffle = mp.shuffle(),
    isDragging = false,
    mouseDown = false,
    hasFriends = true,
    shareSong;

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

// Cookies
if (!hideWelcome && !isOnline) {
  var h1s = $('#welcome h1'),
      h1len = h1s.length,
      h1cur = 0;

  $('#welcome').addClass('active');
  $('#welcome h1:first').addClass('in');

  $('#close-welcome').click(function(e) {
    e.preventDefault();
    $.cookie('hideWelcome', 1);
    $('#welcome').animate({'margin-bottom': '-100px'}, function() {
      $(this).remove();
    });
  });

  setInterval(function() {
    $(h1s[h1cur]).addClass('out');
    if (h1cur == h1len-1) h1cur = -1;
    $(h1s[++h1cur]).addClass('in').removeClass('out')
  }, 4500)
}

//
// Document.ready
//

$(function() {
  // Fade in effect
  $('#overlay').removeClass('shown');
  setTimeout(function() { $('#overlay').removeClass('slow-fade') }, 500);

  // Logged in
  if (!isOnline) {
    modal('#modal-login');
  }

  // Dialog
  hideDialog();

  // Fire initial page load
  page.start();
  page.end();

  // Get volume init
  if (volume === "0") {
    // dont ask me why
    mp.toggleVolume();
    mp.toggleVolume();
  }

  if (shuffle) updateShuffle(shuffle, $('.shuffle'))

  // html5 pushState
  $("a:not(.control)").pjax({
    container: '#body',
    timeout: 12000
  });

  // Mac app download
  // if (navigator.appVersion.indexOf("Mac") != -1) {
  //   $('#sidebar .announce').addClass('ismac');
  // }

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
      pjax('/'+data.url);
    }
  });

  // Player controls
  mpClick('#player-play', 'toggle');
  mpClick('#player-next', 'next');
  mpClick('#player-prev', 'prev');
  mpClick('#player-volume', 'toggleVolume');

  // Song title click
  $('#player-song-name a').click(function() {
    $('.tipsy').remove();
    fn.scrollTo($('section.playing'));
    if (mp.isOnPlayingPage()) return false;
    else mp.doScroll();
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

  // Online friends
  getOnlineFriends();

  // Page scroll functions
  w.scroll(function() {
    // Removes on scroll
    clearTimeout(tipsyClearTimeout);
    tipsyClearTimeout = setTimeout(function(){ $('.tipsy').remove() },100);
    mp.hasMoved(true);

    // Automatic page loading
    if (!loadingPage) {
      clearTimeout(infiniteScrollTimeout);
      infiniteScrollTimeout = setTimeout(function() {
        if (nearBottom()) $('.next-page:visible:last').click();
        // decrementPage();
      }, 20);
    }
  });

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

  $('.collapse').click(function() {
    $(this).parent().toggleClass('collapsed');
  })

  // Link binding
  $('body').on('click', 'a', function bodyClick(e) {
    var el = $(this);
    fn.log('click', el);

    // Disabled
    if (el.is('.disabled')) {
      e.preventDefault();
      return false;
    }
    else {
      if (el.is('.control')) e.preventDefault();
      if (el.is('.nav')) {
        navDropdown($(e.target));
        return false;
      }
      else {
        // Close any dropdowns
        navDropdown(false);
      }

      // Songs
      if (el.is('.song-link')) {
        fn.log('song link')
        mp.playSection(el.parent('section'));
      }

      // Not logged in
      else if (!isOnline && el.is('.restricted')) {
        modal('#modal-login');
        return false;
      }

      // Modals
      else if (el.is('.modal')) {
        modal(e.target.getAttribute('href'));
        return false;
      }

      // Infinite scroll
      else if (el.is('.next-page:not(.loaded)')) {
        // Page load
        nextPage(el);
        return false;
      }

      else if (el.is('.play-station')) {
        mp.setAutoPlay(true);
      }

      else if (el.is('.shuffle')) {
        fn.log('shuffle');
        e.preventDefault();
        shuffled = mp.toggleShuffle();
        updateShuffle(shuffled, el);
      }

      else if (el.is('#more-artists')) {
        var next = $('.artists-shelf li:not(.hidden):lt(5)');
        if (next.length) next.addClass('hidden')
        else $('.artists-shelf li').removeClass('hidden');
      }

      else if (el.is('.close-modal')) {
        modal(false);
      }

      else if (el.is('.show-hide')) {
        $(el.attr('href')).toggleClass('hidden');
        return false;
      }

      else if (el.is('.login-button')) {
        var email = $('#login-email').val();
        if (!fn.validateEmail(email)) {
          e.preventDefault();
          $('#modal-login-form').addClass('has_errors');
          return false;
        } else {
          $('#modal-login-form').removeClass('has_errors');
          $.post('/set_email', {email: email});
        }
      }

      // Always run the below functions

      if (el.is('.popup')) {
        e.preventDefault();
        var el = $(this),
            url = el.attr('href'),
            dimensions = el.data('dimensions').split(',');

        fn.popup(url, dimensions[0], dimensions[1]);
      }
    }
  });

  // Clicks not on a
  $('body').on('click', function() {
    var el = $(this);

    // Update last position (for loading spinner)
    lastPosition = [e.pageX, e.pageY];

    // Hide dropdowns on click
    if (!el.is('a')) navDropdown(false);
  });

  $('.select-on-click').click(function() {
    $(this).select();
  })

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
});

function notice(message, time) {
  $('<div id="dialog">' + message + '</div>').prependTo('#body');
  hideDialog(time);
}

function hideDialog(time) {
  time = time || 3;
  setTimeout(function () {
    $('#dialog').animate({opacity:'0'}, 500, function() {
      $(this).hide();
    });
  }, time * 1000);
}

function updateShuffle(shuffled, el) {
  fn.log('shuffled = ', shuffled);
  if (shuffled) el.addClass('active');
  else el.removeClass('active');
}

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
  fn.log(page, navItems);
  if (navActive) navActive.removeClass('active');
  var newNavActive = navItems[page];
  if (newNavActive) navActive = newNavActive.addClass('active');
}

// Reads URL parameters for ?page=X and returns X
function getPage() {
  var page = window.location.search.match(/p=([0-9]+)/);
  return page ? parseInt(page[1],10) : 1;
}

function updatePageURL(page) {
  var url = mp.getPage(),
      page = 'p=' + page,
      page_regex = /p=[0-9]+/,
      hash = window.location.hash;

  // Replace old page
  if (url.match(page_regex)) {
    url = url.replace(page_regex, page);
  } else {
    url += url.match(/\?/) ? '&' + page : '?' + page;
  }

  url += hash;
  window.history.replaceState(null,document.title,url);
  mp.updatePage(url);
}

function nextPage(link, callback) {
  var link = link.html('Loading').addClass('loading');
  // Infinite scrolling
  if (morePages) {
    var curPlaylist = $('.playlist:visible:last'),
        curPlaylistInfo = curPlaylist.attr('id').split('-'),
        id = curPlaylistInfo[1]
        page = curPlaylistInfo[2];

    loadingPage = true;
    scrollPage = parseInt(page,10) + 1;
    $.ajax({
      url: mp.getPage(),
      type: 'get',
      data: 'id=' + id + '&p=' + scrollPage,
      headers: {
        Accept: "text/page; charset=utf-8",
        "Content-Type": "text/page; charset=utf-8"
      },
      success: function(data) {
        var playlist = $('#playlist-' + id + '-' + scrollPage);
        link.html('Page ' + scrollPage).addClass('loaded');
        loadingPage = false;
        updatePageURL(scrollPage);
        link.after(data);
        pageEndOffsets.push(curPlaylist.offset().top + curPlaylist.height());
        if (callback) callback.call(playlist);
      },
      error: function() {
        morePages = false;
      }
    })
  }
}

function pjax(url, container) {
  $.pjax({
    url: url,
    container: container || '#body',
    timeout: 12000
  });
}

function nearBottom() {
  return w.scrollTop() >= ($(document).height() - $(window).height() - 1400);
}

function navDropdown(nav, pad) {
  fn.log(nav, pad);
  if (nav && nav.length) {
    var pad = pad ? pad : parseInt(nav.attr('data-pad'), 10),
        padding = pad ? pad : 20,
        target = nav.attr('href')[0] == '#' ? nav.attr('href') : nav.attr('data-target'),
        dropdown = $(target).removeClass('hidden').addClass('open'),
        top = nav.offset().top - $('body').scrollTop() + nav.height() + padding,
        left = Math.floor(nav.offset().left + (nav.outerWidth()/2) - (dropdown.width()/2));

    // If the nav is not already open
    if (!(navOpen && navOpen[0] == dropdown[0])) {
      fn.log('opening', dropdown);
      navOpen = dropdown.css({
        top: top,
        left: left
      });

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
    show.attr('class', '');
    $('body').removeClass('modal-shown');
    modalShown = false;
  }
  else {
    modal.html($(selector).clone());
    show.addClass('shown').addClass(selector.substring(1));
    $('body').addClass('modal-shown');
    modalShown = true;

    if (selector == '#modal-user') {
      var login = $('#user_login');
      if (login.val() != '') {
        $('#sign-in').focus();
      } else {
        $('#user_username').focus();
      }
    }
  }
}

function getOnlineFriends() {
  fn.log('online?', isOnline)
  if (isOnline) {
    getFriends();
    setInterval(getFriends, 60 * 1000);
  }
}

function getFriends() {
  fn.log(hasFriends);
  if (hasFriends) {
    $.get('/get_friends', function getFriendsCallback(data) {
      if (data && data.length) $('#stations-inner').html(data);
      else hasFriends = false;
    });
  }
}