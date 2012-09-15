// Variables
var w = $(window),
    songOffsets = [],
    scrollDelayTimeout,
    notScrolling = true,
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
    hideWelcome = $.cookie('hideWelcome'),
    volume = mp.volume(),
    playMode = mp.playMode(),
    isDragging = false,
    mouseDown = false,
    hasNavbar = true,
    shareSong,
    navHovered = [],
    navUnhoveredOnce = false,
    friendsTemplate = $('#friends').html(),
    navbarInterval,
    playModeEl = $('#player-mode');

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

  if (playMode != 'normal') updatePlayMode(playMode);

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
  startGetNavbar();

  // Custom scrollpanes
  $('#stations-inner').bind('mousewheel DOMMouseScroll', function(e) {
    var delta = e.wheelDelta || -e.detail;
    this.scrollTop += ( delta < 0 ? 1 : -1 ) * 30;
    e.preventDefault();
  });

  // Scroll functions
  w .on('scrollstart', function() {
      fn.log('start scrolling');
      $('.tipsy').remove();
      $('.pop-menu').removeClass('open');
      mp.hasMoved(true);
    })
    // window.scroll
    .scroll(function() {
      // Automatic page loading
      if (!loadingPage) {
        clearTimeout(infiniteScrollTimeout);
        infiniteScrollTimeout = setTimeout(function() {
          if (nearBottom()) {
            var lastPlaylist = $('.playlist:visible:last');
            if (lastPlaylist.length && lastPlaylist.is('.has-more')) nextPage(lastPlaylist);
          }
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
  });

  // Share hover
  $('#player-share').hover(function() {
    var el = $(this);
    updateShareLinks(el.data('link'), el.data('title'));
    updateShareFriends(null);
  });

  // Bind hovering on nav elements
  bindNavHover();

  // Share click
  $('#share-friends').on('click', 'a', function() {
    var el = $(this);
    $.post('/share', {
      receiver_id: el.data('user'),
      song_id: shareSong
    }, function() {
      notice('Sent song to ' + el.text());
    });

    return false;
  });

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
      if (el.is('.nav:not(.active)')) {
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

      else if (el.is('.play-station')) {
        mp.setAutoPlay(true);
      }

      else if (el.is('#player-mode')) {
        e.preventDefault();
        updatePlayMode(mp.nextPlayMode());
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

      else if (el.is('#nav-shares')) {
        el.children('span').remove();
      }

      // Always run the below functions

      if (el.is('.popup')) {
        e.preventDefault();
        var el = $(this),
            url = el.attr('href'),
            dimensions = el.data('dimensions').split(',');

        fn.popup(url, dimensions[0], dimensions[1]);
        return false;
      }
    }
  });

  // Clicks not on a
  $('body').on('click', function(e) {
    var el = $(e.target);

    // Update last position (for loading spinner)
    lastPosition = [e.pageX, e.pageY];

    // Hide dropdowns on click
    console.log(el, el.is('input'))
    if (!el.is('a,input')) navDropdown(false);
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
  $('#dialog').remove();
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

function updatePlayMode(mode) {
  playModeEl
    .removeClass('pictos-normal pictos-shuffle pictos-repeat')
    .addClass('pictos-' + mode)
    .html(fn.capitalize(mode));
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
  // Update #navbar
  fn.log(page, navItems);
  if (navActive) navActive.removeClass('active');
  var newNavActive = navItems[page];
  if (newNavActive) navActive = newNavActive.addClass('active');

  // Update .nav-menu
  $('.nav-menu a').removeClass('active');
  $('.nav-menu a[href="' + page + '"]').addClass('active');
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
  fn.replaceState(url);
  mp.updatePage(url);
}

function nextPage(playlist) {
  // Infinite scrolling
  if (morePages && playlist) {
    var link = playlist.next('.next-page').html('Loading...'),
        playlistInfo = playlist.attr('id').split('-'),
        id = playlistInfo[1]
        page = parseInt(playlistInfo[2], 10);

    loadingPage = true;
    scrollPage = page + 1;

    fn.log(id, scrollPage, mp.getPage());

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
        link.after(data);
        updatePlaylist();
        updatePageURL(scrollPage);
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

function bindNavHover() {
  // Hover binding
  $('.nav-hover').hover(function(e) {
    var el = $(this);
    if (!navHovered[el.attr('class')]) navDropdown(el, false, true);
    navHovered[el.attr('class')] = true;
  }, function() {
    var el = $(this);
    var navHoverInterval = setInterval(function() {
      if (!el.is(':hover') && !$(el.attr('href')).is(':hover')) {
        navUnhoveredOnce = true;
        if (navUnhoveredOnce) {
          navDropdown(false);
          clearInterval(navHoverInterval);
          navHovered[el.attr('class')] = false;
          navUnhoveredOnce = false;
        }
      }
    }, 150);
  }).click(function() {
    return false;
  });
}

function navDropdown(nav, pad, hover) {
  fn.log(nav, pad);
  var delay = hover ? 100 : 0;
  setTimeout(function() {
    if (nav && nav.length) {
      if (hover && !nav.is(':hover')) return false;
      var navIsShare = false;
      if (nav.is('.song-share')) {
        navIsShare = true;
        updateShare(nav);
      }

      var pad = pad ? pad : parseInt(nav.attr('data-pad'), 10),
          padding = pad ? pad : 10,
          target = nav.attr('href')[0] == '#' ? nav.attr('href') : nav.attr('data-target'),
          dropdown = $(target).removeClass('hidden').addClass('open'),
          top = nav.offset().top - $('body').scrollTop() + nav.height() + padding,
          left = Math.floor(nav.offset().left + (nav.outerWidth()/2) - (dropdown.width()/2));

      // If the nav is not already open
      if (!(navOpen && navOpen[0] == dropdown[0])) {
        navOpen = dropdown.css({
          top: top,
          left: left
        });

        if (navIsShare) {
          fn.clipboard('share-link', 'relative');
        }

        return true;
      }
    }

    if (navOpen) navOpen.removeClass('open').addClass('hidden');
    navOpen = false;
  }, delay);
}

function updateShare(nav) {
  var id = nav.data('id'),
      section = $('#song-' + id),
      index = section.data('index'),
      playlist = $('#playlist-' + section.data('station')).data('playlist'),
      song = playlist.songs[index],
      link = 'http://2u.fm/songs/' + section.data('slug'),
      title = (song.artist_name || '') + ' - ' + (song.name || ''),
      share = $('#share');

  fn.log(section, index, playlist, song);
  shareSong = id;
  updateShareLinks(link, title);
  updateShareFriends(true);
}

function updateShareLinks(link, title) {
  $('#share .player-invite').each(function() {
    var el = $(this),
        dataLink = el.data('link'),
        url = dataLink.replace('{{url}}', encodeURIComponent(link)).replace('{{text}}', encodeURIComponent('Listening to ' + title));
    el.attr('href', url);
  });

  // Update link
  $('#share-link').attr('href', link);
}

function updateShareFriends(friends) {
  if (friends === true) {
    $('#share-friends').show();
  } else if (friends) {
    $('#share-friends').html(friends);
  } else {
    $('#share-friends').hide();
  }
}

function updatePlaylist() {
  if (isOnline) {
    updateFollows();
    updateBroadcasts();
    updateListens();
  }
  updateTimes();
  updateCounts();
}

function updateCounts() {
  for (var key in updateBroadcastsCounts) {
    $('#song-' + key).children('.song-meta').find('.song-controls .broadcast a').html(updateBroadcastsCounts[key]);
  }
}

function updateTimes() {
  $('time').each(function() {
    var el = $(this),
        datetime = new Date(el.attr('datetime')).toRelativeTime();
    el.html(datetime);
  });
}

function updateListens() {
  if (!updateListensIds || updateListensIds.length == 0) return false;
  var select = '#song-',
      songs = select + updateListensIds.join(',' + select);

  $(songs).addClass('listened-to');
}

function updateBroadcasts() {
  if (!updateBroadcastsIds || updateBroadcastsIds.length == 0) return false;
  var select = '#song-',
      songs = select + updateBroadcastsIds.join(',' + select),
      b = {
        title: 'Unlike this song',
        method: 'delete'
      };

  $(songs).each(function() {
    var broadcast = $(this).children('.song-meta').find('.song-controls .broadcast a');
    broadcast
      .attr('title', b.title)
      .data('method', b.method)
      .removeClass('add')
      .addClass('remove');
  });
}

function updateFollows() {
  if (!updateFollowsIds || updateFollowsIds.length == 0) return false;
  var follows,
      len = updateFollowsIds.length,
      i = 0,
      f = {
        icon: '2',
        html: 'Following',
        title: 'Unfollow station',
        method: 'delete'
      };

  for (; i < len; i++) {
    updateFollowsIds[i] += ' a';
  }

  if (len > 1) {
    follows = '.follow-' + updateFollowsIds.join(', .follow-');
  } else {
    follows = '.follow-' + updateFollowsIds[0];
  }

  $(follows)
    .attr('title', f.title)
    .data('method', f.method)
    .removeClass('add')
    .addClass('remove')
    .html('<span>' + f.icon + '</span><strong>' + f.html + '</strong>');
}

function setFollowsIds(ids) {
  updateFollowsIds = ids;
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

function startGetNavbar() {
  fn.log('online?', isOnline)
  if (isOnline) {
    getNavbar();
    navbarInterval = setInterval(getNavbar, 60 * 1000);
  }

  // Stopgap... stop polling after an hour
  setTimeout(function() {
    clearInterval(navbarInterval);
  }, 60 * 60 * 1000);
}

function getNavbar() {
  fn.log('?', hasNavbar);
  if (hasNavbar) {
    $.getJSON('/navbar.json', function getNavbarCallback(data) {
      fn.log('got', data);
      if (data) {
        var inbox_count = parseInt(data['inbox_count'],10);
        if (inbox_count > 0) {
          $('#nav-shares span').remove();
          $('#nav-shares').append('<span>' + inbox_count + '</span>');
        }

        var friendsHtml = Mustache.render(friendsTemplate, data['friends']);
        $('#stations-inner').html(friendsHtml).find('img').load(function() {
          $(this).removeClass('hidden');
        });
        updateShareFriends(friendsHtml);
      }
      else {
        hasNavbar = false;
      }
    });
  }
}