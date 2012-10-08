// Variables
var w = $(window),
    songOffsets = [],
    scrollDelayTimeout,
    notScrolling = true,
    infiniteScrollTimeout,
    debug = false,
    isOnline = $('body.signed_in').length > 0,
    isAdmin = $('body[data-role="admin"]').length > 0,
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
    friendsTemplate = $('#friends-template').html(),
    navbarInterval,
    playModeEl = $('#player-mode'),
    modeTitles = {'normal': 'Normal', 'repeat': 'Repeat', 'shuffle': 'Shuffle'},
    playAfterLoad,
    doPjax = true,
    isTuningIn = typeof(tuneInto) != 'undefined',
    newCurPage,
    doc;

doc = ($.browser.chrome || $.browser.safari) ? $('body') : $('html');

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
  if (!isOnline && !isTuningIn) {
    modal('#modal-login');
  }

  if (isTuningIn) {
    tuneIn(tuneInto, function() {
      if (typeof(beginListen) != 'undefined') {
        goToListen(beginListen);
      }
    });
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
  $("a:not(.control)").live('click', function(e) {
    e.preventDefault();
    if (doPjax) {
      $.pjax({
        url: $(this).attr('href'),
        container: '#body',
        timeout: 12000
      });
    } else {
      loadPage($(this).attr('href'));
    }
  });

  // Mac app download
  // if (navigator.appVersion.indexOf("Mac") != -1) {
  //   $('#sidebar .announce').addClass('ismac');
  // }

  // Listen sharing auto play
  playFromParams();

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
  $('#player-song-name a').click(function songNameClick() {
    fn.log('onplayingpage', mp.isOnPlayingPage());
    $('.tipsy').remove();
    if (mp.isOnPlayingPage()) {
      scrollToCurrentSong();
      return false;
    }
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
  $('#stations-inner, #share-friends').dontScrollParent();

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
    var el = $(this),
        curSong = mp.curSongInfo();
    updateShareLinks(el.data('link'), el.data('title'));
    updateShareFriends(true);
    shareSong = curSong.id;
    shareSongTitle = curSong.name || '';
  });

  // Bind hovering on nav elements
  $('.nav-hover').live({
    mouseenter: function(e) {
      var el = $(this),
          hoveredClass = el.attr('class'),
          hovered = navHovered[hoveredClass];

      fn.log('nav hover.. hovered?', hoveredClass, hovered, el);
      if (!hovered) navDropdown(el, false, true);
      navHovered[hoveredClass] = true;
    },
    mouseleave: function() {
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
    },
    click: function() {
      return false;
    }
  });

  // Share click
  $('#share-friends').on('click', 'a', function() {
    var el = $(this);
    $.post('/share', {
      receiver_id: el.data('user'),
      song_id: shareSong
    }, function() {
      notice('Sent <b>' + shareSongTitle + '</b> to <b>' + el.text() + '</b>');
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

      else if (el.is('#nav-shares')) {
        el.children('span').remove();
      }

      else if (el.is('.add-comment')) {
        showComments(el.attr('href'));
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

      if (el.is('.nav:not(.active)')) {
        navDropdown($(e.target));
        return false;
      }
      else {
        // Close any dropdowns
        navDropdown(false);
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
    .html(fn.capitalize(modeTitles[mode]));
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
      statusCode: {
        204: function() {
          removeNextPage(link);
          return false;
        }
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
        removeNextPage(link);
      }
    })
  }
}

function removeNextPage(link) {
  morePages = false;
  link.remove();
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

function navDropdown(nav, pad, hover) {
  var delay = hover ? 100 : 0;
  setTimeout(function() {
    if (nav && nav.length) {
      fn.log(nav, pad, 'class=', nav.attr('class'));
      if (hover && !nav.is(':hover')) return false;
      if (nav.is('.song-share')) {
        updateShare(nav);
      }

      var pad = pad ? pad : parseInt(nav.attr('data-pad'), 10),
          padding = pad ? pad : 10,
          target = nav.attr('href')[0] == '#' ? nav.attr('href') : nav.attr('data-target'),
          dropdown = $(target).removeClass('hidden').addClass('open'),
          top = nav.offset().top - doc.scrollTop() + nav.height() + padding,
          left = Math.floor(nav.offset().left + (nav.outerWidth()/2) - (dropdown.width()/2));

      // If the nav is not already open
      if (!(navOpen && navOpen[0] == dropdown[0])) {
        navOpen = dropdown.css({
          top: top,
          left: left
        });

        if (nav.is('.update-clipboard')) {
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
  fn.log('update share nav', nav);
  var id = nav.data('id'),
      section = $('#song-' + id),
      index = section.data('index'),
      playlist = $('#playlist-' + section.data('station')).data('playlist'),
      song = playlist.songs[index],
      listen = section.data('listen'),
      link = 'http://2u.fm/' + (listen ? ('l/' + listen) : ('songs/' + section.data('slug'))),
      title = (song.artist_name || '') + ' - ' + (song.name || ''),
      share = $('#share');

  fn.log(section, index, playlist, song);
  shareSong = id;
  shareSongTitle = song.name || '';
  updateShareLinks(link, title);
  updateShareFriends(true);
}

function updateShareLinks(link, title) {
  $('#share .player-invite').each(function() {
    var el = $(this),
        dataLink = el.data('link'),
        url = dataLink.replace('{{url}}', encodeURIComponent(link)).replace('{{text}}', encodeURIComponent('Listening to ♫ ' + title));
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
  fn.log('Updating, isOnline?', isOnline);

  if (isOnline) {
    updateFollows();
    updateBroadcasts();
    updateListens();

    if (isAdmin) {
      $('.playlist.not-loaded section').each(function() {
        var id = $(this).attr('id').split('-')[1];
        $('.song-controls', this).append('<a class="no-external control" download="'+id+'.mp3" href="http://media.2u.fm/song_files/' + id + '_original.mp3">DL</a>');
      })
    }
  }
  updateTimes();
  updateCounts();
  $('.playlist.not-loaded').removeClass('not-loaded').addClass('loaded');
}

function updateCounts() {
  for (var key in updateBroadcastsCounts) {
    $('#song-' + key).children('.song-meta').find('.song-controls .broadcast a').html(updateBroadcastsCounts[key]);
  }
}

function updateTimes() {
  $('.playlist.not-loaded time').each(function() {
    var el = $(this),
        datetime = new Date(el.attr('datetime')).toRelativeTime();
    el.html(datetime);
  });
}

function updateListens() {
  if (!updateListensIds) return false;
  for(var key in updateListensIds) {
    $('#song-' + key).addClass('listened-to').attr('data-listen', updateListensIds[key]);
  }
}

function updateBroadcasts() {
  if (!updateBroadcastsIds || updateBroadcastsIds.length == 0) return false;
  var select = '#song-',
      songs = select + updateBroadcastsIds.join(',' + select),
      b = {
        title: 'Unlike this song',
        method: 'delete'
      };

  fn.log(songs);
  $(songs).each(function() {
    var broadcast = $(this).addClass('liked').children('.song-meta').find('.song-controls .broadcast a');
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

  $('.playlist.not-loaded ' + follows)
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
    if (!modal.children('.permanent').length) {
      show.attr('class', '');
      $('body').removeClass('modal-shown');
      modalShown = false;
    }
  }
  else {
    modal.html($(selector).clone());
    show.addClass('shown').addClass(selector.substring(1));
    $('body').addClass('modal-shown');
    modalShown = true;
    $('input:first', modal).focus();
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
        $('#stations-inner')
          .html(friendsHtml)
          .find('img')
          .load(function() {
            $(this).removeClass('hidden');
          });
        updateShareFriends(friendsHtml);

        $('#friends').html(friendsHtml);
      }
      else {
        hasNavbar = false;
      }
    });
  }
}

function scrollToCurrentSong() {
  fn.scrollTo($('section.playing'));
}

function resetMorePages() {
  morePages = true;
}

function playFromParams() {
  updateParams.run();
  if (urlParams['play']) {
    var song = urlParams['song'];
    var section = $('#song-' + song);
    mp.playSection(section);
  }
}

function playAfterRouting() {
  if (playAfterLoad) {
    clickSong(playAfterLoad);
    playAfterLoad = null;
  }
}

function clickSong(id) {
  $('#song-' + id + ' .play-song').click();
}

function tuneIn(id, callback) {
  fn.log(id)
  loadPage('/tune/' + id, function() {
    doPjax = false;
    if (callback) callback.call();
  });
}

function tuneOut() {
  doPjax = true;
}

function goToListen(listen) {
  var now = Math.round((new Date()).getTime() / 1000),
      seconds_past = now - parseInt(listen.created_at_unix, 10);

  if (listen.url.replace(/\?.*/, '') == mp.curPage()) {
    clickSong(listen.song_id);
  } else {
    playAfterLoad = listen.song_id;
    loadPage(listen.url);
  }
}

function loadPage(url, callback) {
  newCurPage = url;
  page.start();
  $.ajax({
    url: url,
    dataType: 'html',
    beforeSend: function(xhr){
      xhr.setRequestHeader('X-PJAX', 'true')
    },
    success: function(data) {
      $('#body').html(data);
      page.end();
      if (callback) callback.call();
    }
  });
}