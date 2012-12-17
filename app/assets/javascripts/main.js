//Danthes.debug = true;

// Don't remember scroll position if they were on a page
if (window.location.pathname.match(/p-[0-9]+/)) {
  fn.scrollToTop(0);
}

//
// Document.ready
//
$(function() {
  // Dialog
  $('#dialog').appendTo('body');
  hideDialog();

  // Detect fucking idiotic mountain lion scrollbars
  setTimeout(function() {
    if ($('#navbar-genres-wrap').width() == 165) {
      body.addClass('stupid-mountain-lion');
    }
  }, 0);

  // Listen playing
  if (listen) {
    // mp.startedAt(listen.created_at_unix);
    fn.replaceState(route);
  }

  // Fire initial page load
  page.start();
  page.end();

  if (listen) {
    clickSong(listen.song_id);
  } else {
    resumePlaying();
  }

  // Modal if not logged in
  if (!doPlaysActions()) {
    $('#overlay').removeClass('shown');
  }

  if ($('#modal-new-user').length) {
    modal('#modal-new-user');

    $('#modal-new-user .genres a').click(function(e) {
      e.preventDefault();
    });

    $('#genres-next').click(saveUserGenres);

    $('#recommended-artists-next').click(function() {
      $('#modal-new-user').removeClass('permanent');
    });
  }

  if (hideCorner == 1) $('#close-corner-banner').click();

  // Welcome
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

  // Listen sharing auto play
  playFromParams();
});

doc = ($.browser.chrome || $.browser.safari) ? body : $('html');

pageEvents();

setNavItems();

if (isOnline) {
  // Analytics for users
  _gaq.push([ '_setCustomVar', 1, 'User', 'Session', $('body').data('user'), 1 ]);

  $('.remove')
    .live('mouseenter', function() { $('span',this).html('D'); })
    .live('mouseleave', function() { $(this).removeClass('first-hover').find('span').html('2'); });
}

// Theme
if (theme.body !== 'theme-body-1') {
  body.addClass(theme.body).removeClass('theme-body-1');
}

if (theme.head !== 'theme-head-1') {
  body.addClass(theme.head).removeClass('theme-head-1');
}

// Get volume init
if (mp.volume() !== "100") {
  mp.setVolume(mp.volume());
}

if (mp.playMode() != 'normal')
  updatePlayMode(mp.playMode());

// Tooltips
$('.tip:not(.disabled)').tipsy({gravity: 's', offset: 5, live: true});
$('.tip-n:not(.disabled)').tipsy({gravity: 'n', offset: 5, live: true});
$('.tip-e:not(.disabled)').tipsy({gravity: 'e', offset: 5, live: true});
$('.tip-w:not(.disabled)').tipsy({gravity: 'w', offset: 5, live: true});

// window.scroll
w
  .on('scrollstart', function() {
    $('.tipsy').remove();
    navDropdown(false);
    mp.hasMoved(true);
    disableHovers = true;
  })
  .on('scrollstop', function() {
    disableHovers = false;
  })
  .on('pageLoaded', function() {
    updatePlaylist();
  });

w.resize(fn.debounce(windowResize, 20));

function windowResize() {
  var navbarHeight = Math.min($('body').height(), $('#navbar-menus-inner').outerHeight());

  $('#navbar-friends-inner')
    .css({ 'height': ($('body').height() - $('#navbar-menus-inner').outerHeight() - 32) })

  $('#navbar-menus')
    .css({ 'height': navbarHeight })

  var modal = $('#modal.shown');
  if (modal.length) {
    fn.log(modal.height() + $('header').height(), '>', w.height())
    if (modal.height() + $('header').height() > w.height()) {
      modal.css('bottom', '1px');
    } else {
      modal.css('bottom', 'auto');
    }
  }

  if (w.width() <= 768) {
    $('.scroll-bound').unbind('mousewheel DOMMouseScroll');
  } else {
    // Custom scrollpanes
    $('#share-friends').dontScrollParent();

    $('.scroll-section-inner').trigger('scrollbar:content:changed')
    $('.scroll-section:not(.inner-scroll-bound)').each(function() {
      var div = $('div', this)[0];
      if (div) {
        $(div).addClass('scroll-section-inner').dontScrollParent();
        $(this).addClass('inner-scroll-bound');
      }
    });
  }
}

function updatePlayerShare() {
  var el = $('#player-share'),
      curSong = mp.curSongInfo();

  updateShareLinks(el.data('link'), el.data('title'));
  updateShareFriends(true);
  shareSong = curSong.id;
  shareSongTitle = curSong.name || '';
}

// Share click
body.on('click', '#share-friends a', function() {
  var el = $(this);
  $.ajax({
    type: 'post',
    url: '/share',
    data: {
      receiver_id: el.data('user'),
      song_id: shareSong
    },
    success: function() {
      notice('Sent <b>' + shareSongTitle + '</b> to <b>' + el.text() + '</b>');
    },
    error: function(xhr) {
      notice(xhr.responseText.replace('{{user}}', el.text()));
    }
  });

  return false;
});

body.on('click', 'a.restricted', function() {
  if (!isOnline) {
    modal('#modal-login');
    return false;
  }
});

body.on('click', '#player-song-name a', function songNameClick() {
  $('.tipsy').remove();
  if (mp.isOnPlayingPage()) {
    scrollToCurrentSong();
    return false;
  }
});

body.on('click', '#modal #sign-up-button', function(e) {
  e.preventDefault();
  registerUser($(this));
});

body.allOn('click', {
  // Player controls
  '#player-play': function(e) {
    e.preventDefault();
    mp.toggle();
  },

  '#player-next': function(e) {
    e.preventDefault();
    mp.next();
  },

  '#player-prev': function(e) {
    e.preventDefault();
    mp.prev();
  },

  '.disabled': function() {
    return false;
  },

  '.control': function(e) {
    e.preventDefault();
  },

  '.song-link': function(e, el) {
    if (mp.isLive()) return;
    mp.playSection(el.parent('section'));
  },

  '.modal': function(e, el) {
    modal(el.attr('href'));
    return false;
  },

  '.modal-close': function() {
    modal(false);
  },

  '.popup': function(e, el) {
    e.preventDefault();
    popup(el);
  },

  '.select-on-click': function(e, el) {
    el.select();
  },

  '[data-toggle]': function(e, el) {
    if (!$(e.target).is('[data-toggle]')) return;
    $(el.attr('href')).toggleClass(el.attr('data-toggle'));
    el.toggleClass('toggled');
  },

  '[data-toggle-html]': function(e, el) {
    var newhtml = el.attr('data-toggle-html');
    el.attr('data-toggle-html', el.html()).html(newhtml);
  },

  '.multi-select a': function(e, el) {
    el.toggleClass('selected');
    return false;
  },

  '.nav:not(.active)': function(e) {
    navDropdown($(e.target));
    return false;
  },

  '.play-station': function() {
    mp.setAutoPlay(true);
  },

  '.add-comment': function(e, el) {
    showComments(el.attr('href'));
  },

  '.nav-menu a.control': function(e, el) {
    $('.nav-menu a.active').removeClass('active');
    el.addClass('active');
    $('.nav-container div.active').removeClass('active');
    sectionActive = $(el.attr('href')).addClass('active');
    return false;
  },

  '#player-mode': function(e) {
    e.preventDefault();
    updatePlayMode(mp.nextPlayMode());
  },

  '#player-volume-icon': function(e, el) {
    if ($(e.target).is('#player-volume-icon')) {
      mp.toggleVolume();
    }
  },

  '#more-artists': function() {
    var next = $('.artists-shelf li:not(.hidden):lt(5)');
    if (next.length > 3) next.addClass('hidden');
    else $('.artists-shelf li').removeClass('hidden');
  },

  '.modal-force-close': function() {
    modal(false, true);
  },

  '#navbar a': function() {
    if ($('#mobile-nav').is(':visible')) {
      $('body').toggleClass('show-nav');
    }
  },

  '#flag a': function() {
    notice('Flagged song ' + $(this).html());
  },

  '#save-genres': function() {
    saveUserGenres();
  },

  '#overlay': function() {
    modal(false);
  },

  '#mobile-nav': function() {
    $('body').toggleClass('show-nav');
  },

  '#head-colors a': function(e, el) {
    e.preventDefault();
    var old = theme.head;
    theme.head = el.attr('href');
    if (old != theme.head) {
      body.addClass(theme.head);
      body.removeClass(old);
      $.cookie('theme-head', theme.head);
    }
  },

  '#body-colors a': function(e, el) {
    e.preventDefault();
    var old = theme.body;
    theme.body = el.attr('href');
    if (old != theme.body) {
      body.addClass(theme.body);
      body.removeClass(old);
      $.cookie('theme-body', theme.body);
    }
  },

  '#buttons .broadcast a': function(e, el) {
    el.parent().toggleClass('remove');
  },

  '#navbar [href=#navbar-genres]': function() {
    setTimeout(function() {
      $.cookie('genres-open', !$('#navbar-genres').is('.invisible'));
      windowResize();
    }, 210);
  },

  '#close-corner-banner': function(e, el) {
    cornerBanner.toggleClass('closed');
    var closed = cornerBanner.is('.closed');
    $.cookie('hideCorner', closed ? 1 : 0);
    if (closed) cornerBanner.css({ right: '-' + (cornerBanner.width() - $('#close-corner-banner').outerWidth()) + 'px' });
    else cornerBanner.css({ right: 0 });
  }
});

body.allOn('click', {
  'a': function bodyClick(e, el) {
    fn.log(e, el);

    try {
      var id = el.attr('id'),
          classname = el.attr('class'),
          href = 'href=' + el.attr('href'),
          tagid = id ? ('#' + id + ' ') : '',
          tagclass = classname ? ('.' + classname.split(' ').join('. ')) : '',
          identifiers = tagid + tagclass,
          tag = href + ( identifiers ? ' || ' + identifiers : '' );
      fn.log('tracking', tag);
      _gaq.push(['_trackEvent', tag, 'Click', el.text()]);
    }
    catch (err) {
      fn.log(err);
    }

    if (!e.isDefaultPrevented() && !commandPressed) {
      e.preventDefault();
      if (doPjax) pjax(el.attr('href'), el.is('.full-request'));
      else loadPage(el.attr('href'));
    }
  }
});

// Clicks not on a
body.on('click', function(e) {
  var el = $(e.target);

  // Hide dropdowns on click
  if (!el.parents('.pop-menu, .nav-menu')) navDropdown(false);
})
  .on('hover', '[data-remote]', function(e) {
    spinner.updatePos(e.pageX, e.pageY);
  });

if ($.cookie('genres-open') === 'false') {
  $('#navbar [href=#navbar-genres]').click();
}



// functions

var dialogTimeout;
function notice(message, time) {
  clearTimeout(dialogTimeout);
  $('#dialog').remove();
  $('<div id="dialog">' + message + '</div>').prependTo('body');
  hideDialog(time);
}

function hideDialog(time) {
  dialogTimeout = setTimeout(
    function () {
      $('#dialog').fadeOut(200, function() {
        $(this).remove();
      });
    },
    (time || 3) * 1000
  );
}

function updatePlayMode(mode) {
  var modeHTML = {'normal': 'Normal', 'repeat': 'Repeat', 'shuffle': 'Shuffle'},
      modeTitles = {'normal': 'Toggle shuffle/repeat', 'repeat': 'Repeat', 'shuffle': 'Shuffle'};

  $('#player-mode')
    .removeClass('icon-normal icon-shuffle icon-repeat')
    .addClass('icon-' + mode)
    .html(fn.capitalize(modeHTML[mode]))
    .attr('title', modeTitles[mode]);

  $('.tipsy').remove();
  $('#player-mode').trigger('mouseenter');
}

function setNavItems() {
  $('#navbar a').each(function() {
    var t = $(this);
    navItems[t.attr('href')] = t;
  });
}

function setNavActive(page) {
  fn.log(page);
  if (!page) return;
  page = page.replace(/\/p-[0-9]+.*/, '');

  // Update #navbar
  if (navActive) navActive.removeClass('active');
  var newNavActive = navItems[page],
      split = page;

  // Descending path highlight
  while (!newNavActive) {
    split = split.split('/');
    split = split.slice(0, split.length - 1).join('/');
    if (split == '') break;
    fn.log('testing highlight of ', split, navItems);
    newNavActive = navItems[split];
  }

  if (newNavActive) navActive = newNavActive.addClass('active');

  // Update .nav-menu
  $('.nav-menu a').removeClass('active');

  var newNavEl = $('.nav-menu a[href="' + page + '"]')
  if (!newNavEl.length) {
    var split = page.split('/');
    newNavEl = $('.nav-menu a[href="' + split.slice(0, split.length - 1).join("/") + '"]')
  }

  newNavEl.addClass('active');
}

function pjax(url, full) {
  if (full) doPageEvents = true;
  nextUrl = url;
  $.pjax({
    url: url,
    container: full ? '#full' : '#body',
    timeout: 30000,
    fullRequest: full || false
  });
}

function updateShare(nav) {
  fn.log('update share nav', nav);
  var id = nav.data('id'),
      section = $('#song-' + id),
      index = section.data('index'),
      playlist = $('#playlist-' + section.data('station')).data('playlist'),
      song = playlist.songs[index],
      listen = section.attr('data-listen'),
      link = 'http://' + location.host + '/' + (listen ? ('l/' + listen) : ('songs/' + section.data('slug'))),
      title = (song.artist_name || '') + ' - ' + (song.name || ''),
      share = $('#share');

  fn.log(section, index, playlist, song, listen);
  shareSong = id;
  shareSongTitle = song.name || '';
  updateShareLinks(link, title);
  updateShareFriends(true);
  $('#share-friends').trigger('scrollbar:content:changed');
}

function updateShareLinks(link, title) {
  $('#share .player-invite').each(function() {
    var el = $(this),
        dataLink = el.attr('data-link'),
        url = dataLink.replace('{{url}}', link).replace('{{text}}', encodeURIComponent('Listening to ♫ ' + title + ' @2u_fm'));
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

function updateBuy(nav) {
  var id = nav.data('id');
  $('#buy a').each(function() {
    var link = $(this);
    link.attr('href', link.attr('href').replace(/[0-9]+$/, id));
  });
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
        $('#navbar-friends').removeClass('hidden');
        var friendsHtml = Mustache.render(friendsTemplate, data['friends']);
        $('#navbar-friends-inner').html(friendsHtml).trigger('scrollbar:content:changed');
        updateShareFriends(friendsHtml);
        setNavItems();
        setNavActive(mp.getPage());

        $('#friends').html(friendsHtml).trigger('scrollbar:content:changed');

        w.trigger('got:friends');
      }
      else {
        hasNavbar = false;
      }
    });
  }
}

w.on('got:friends', function() {
  if (!friendsScrollInited) {
    $('#navbar-friends-inner').scrollbar();
    friendsScrollInited = true;
  }
});

function clickSong(id) {
  fn.log(id);
  mp.playSection($('#song-' + id + ''));
}

function registerUser(button) {
  var form = $('#modal-login').find('#register-form');

  $.ajax({
    url: form.attr('action'),
    type: 'post',
    data: form.serialize(),
    success: function(data) {
      var data = $(data);
      if (data.find('#error_explanation').length) {
        fn.log(data.find('#register-form').html());
        form.html(data.find('#register-form').html());
        windowResize();
      } else {
        window.location = button.attr('href');
      }
    },
    error: function(data) {
    }
  })
}

function popup(el) {
  var url = el.attr('href');

  if (el.data('dimensions')) {
    dimensions = el.data('dimensions').split(',');
    fn.popup(url, dimensions[0], dimensions[1]);
  }
  else {
    fn.popup(url);
  }
}

$(window).on('gotPageLoad', function(e, data) {
  bindImageErrors(data);
});

bindImageErrors();

function bindImageErrors(context) {
  // $('img', context || 'body').error(function imgError() {
  //   var el = $(this);
  //   if (!el.is('.waveform'))
  //     el.attr('error-src', el.attr('src')).attr('src','/images/default.png');
  // });
}

function updateBroadcastButton(station_id, song_id) {
  if (isOnline) {
    var i,
        broadcasts = broadcastedIds[station_id],
        broadcast = $('#buttons .broadcast').removeClass('remove');

    broadcast
      .children('a')
      .attr('href', '/broadcasts/' + song_id);

    if (broadcasts) {
      for (i = 0; i < broadcasts.length; i++) {
        if (broadcasts[i] === song_id) {
          broadcast.addClass('remove');
        }
      }
    }
  }
}

function resumePlaying() {
  fn.log(isOnline, beginListen);
  if (isOnline && beginListen && mp.isOnPlayingPage(beginListen.url)) {
    now = Math.ceil((new Date()).getTime() / 1000),
          seconds_past = now - parseInt(beginListen.created_at_unix, 10);

    // If we're not within the last 5 seconds of a song
    if (seconds_past < beginListen.seconds - 5) {
      mp.startedAt(beginListen.created_at_unix);
      clickSong(beginListen.song_id);
    }
  }
  else if (isOnline) {
    // fn.log('resume playlist');
    // var userLastPlaylist = $('#user-last-playlist');
    // if (userLastPlaylist.length) {
    //   mp.playPlaylist(userLastPlaylist.data('playlist'), userLastPlaylist.data('last-id'));
    // }
  }
}

function setupFixedTitles() {
  return false;
  var fixedTitlesInterval,
      isFixed = false,
      title = $('.title:has(.nav-menu)');

  if (title.length) {
      var titleClone = $('.title').clone().addClass('fixed invisible').appendTo('#body');

    $('h1, h2', titleClone).click(function() {
      fn.scrollToTop();
    });

    clearInterval(fixedTitlesInterval);
    w.on('scrollstart', function() {
      fixedTitlesInterval = setInterval(function() {
        if (doc.scrollTop() > 60) {
          if (!isFixed) {
            title.addClass('invisible');
            titleClone.removeClass('invisible');
            isFixed = true;
          }
        } else {
          title.removeClass('invisible');
          titleClone.addClass('invisible');
          isFixed = false;
        }
      }, 50);
    });

    w.on('scrollstop', function() {
      clearInterval(fixedTitlesInterval);
    });
  }
}

function doPlaysActions() {
  if (!isOnline && !isTuningIn && mp.plays() > 8) {
    if ( !$('#page-identifier').is('.action-trending, .controller-passwords, .controller-mains') ) {
      $('#modal-login').addClass('permanent');
      modal('#modal-login');
      return true;
    } else {
      modal(false, true);
      return false;
    }
  }
}

function afterDataRemoteEvent() {
  $('.tipsy').remove();
  spinner.detach();
  bindDataRemoteEvents();
}

function bindDataRemoteEvents() {
  $('#body a[data-remote]')
    .on('ajax:before', function() {
      spinner.attach();

      // Timeout
      setTimeout(function() {
        spinner.detach();
      }, 3000);
    });
}

function scrollToPlayingSong(section) {
  // Scroll to song
  setTimeout(function() {
    if ( mp.isOnPlayingPage() ) {
      fn.log('scroll to song', section);
      if (section && section.length) {
        var sectionTop = section.offset().top,
            sectionBot = sectionTop + section.height(),
            windowTop  = w.scrollTop(),
            windowBot  = windowTop + w.height();

        if (sectionTop < (windowTop + 220)) fn.scrollTo(section);
        else if (sectionBot > (windowBot - 40)) fn.scrollTo(section);
      }
    }
  }, 200);
}

function saveUserGenres() {
  var genres = [];
  $('.genres.multi-select a.selected').each(function(){
    genres.push($(this).attr('data-id'));
  });

  if (genres.length) {
    $.ajax({
      type: 'post',
      url: '/my/genres',
      data: 'genres=' + genres.join(','),
      success: function(data) {
        $('#new-user-artists .stations').removeClass('loading').html(data);
      }
    });
  } else {
    notice('No genres selected... You gotta like something, right?!');
    return false;
  }
}

function scrollToCurrentSong() {
  var song = $('#song-' + mp.curSongInfo().id);
  if (song.length) fn.scrollTo(song);
}

function pageEvents() {
  doPageEvents = false;

  mp.bindEvents();

  windowResize();

  friendsScrollInited = false;
  $('#navbar-genres-wrap').scrollbar();
  $('#share-friends').scrollbar();

  // Search
  $('#search-form').submit(function searchSubmit() {
    var search = $('#query').val().replace(/[^A-Za-z0-9\-\_\+ ]/g, '').replace(/\s+/g, '+');
    fn.log(search);
    pjax('/do/search/' + search);
    return false;
  });

  $('#query')
    .focus(function() {
      $(this).addClass('focused');
    })
    .blur(function() {
      $(this).removeClass('focused');
    })
    .keyup(function(e) {
      if (e.keyCode == 27 || e.keyCode == 13) $(this).blur();
    })
    .marcoPolo({
      highlight: false,
      submitOnEnter: true,
      url: '/do/search',
      selectable: ':not(.unselectable)',
      formatItem: function (data, $item) {
        if (data.selectable == 'false') $item.addClass('unselectable');
        if (data.header == 'true') $item.addClass('unselectable header');
        return data.name;
      },
      onSelect: function (data, $item) {
        pjax('/' + data.url);
      }
    });

  // Play from playlist
  $('#player-playlist').on('click', 'a', function(e) {
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

  // Share hover
  $('#player-share').hover(updatePlayerShare);
}


// Catch errors
window.onerror = function(msg, url, line) {
  var error = [url, line, msg ].join(newline);
  // if (!isProduction) alert(error);
  fn.log('JS error', error);
  page.end();

  if (isProduction) {
    _prf.error(error);
    _prf.window();
    return true;
  }
}