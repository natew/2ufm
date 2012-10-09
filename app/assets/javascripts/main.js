//
// Document.ready
//
$(function() {
  // Dialog
  hideDialog();

  // Fire initial page load
  page.start();
  page.end();
});

doc = ($.browser.chrome || $.browser.safari) ? body : $('html');

navItems = getNavItems();

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

// Get volume init
if (volume === "0") {
  // dont ask me why
  mp.toggleVolume();
  mp.toggleVolume();
}

if (playMode != 'normal') updatePlayMode(playMode);

// Listen sharing auto play
playFromParams();

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
  $('.tipsy').remove();
  if (mp.isOnPlayingPage()) {
    scrollToCurrentSong();
    return false;
  }
});

function scrollToCurrentSong() {
  fn.scrollTo($('section.playing'));
}

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

// Custom scrollpanes
$('#stations-inner, #share-friends').dontScrollParent();

// window.scroll
w.on('scrollstart', function() {
  fn.log('start scrolling');
  $('.tipsy').remove();
  $('.pop-menu').removeClass('open');
  mp.hasMoved(true);
})
.on('pageLoaded', function() {
  updatePlaylist();
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
    clearInterval(navHoverInterval);
    closeHoveredDropdown();
    if (!hovered) {
      navHoverActive = el;
      navDropdown(el, false, true);
      navHovered[hoveredClass] = true;
    }
  },
  mouseleave: function() {
    navHoverInterval = setInterval(function() {
      closeHoveredDropdown(navHoverActive);
    }, 250);
  },
  click: function() {
    return false;
  }
});

function closeHoveredDropdown() {
  var el = navHoverActive;
  if (el && !el.is(':hover') && !$(el.attr('href')).is(':hover')) {
    navUnhoveredOnce = true;
    if (navUnhoveredOnce) {
      navDropdown(false);
      clearInterval(navHoverInterval);
      navHovered[el.attr('class')] = false;
      navUnhoveredOnce = false;
    }
  }
}

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

body.allOn('click', {
  'a': function(e, el) {
    navDropdown(false);
    if (!this.className.match(/external/)
      e.preventDefault();
    if (!this.className.match(/popup|control/)) {
      if (doPjax) {
        $.pjax({
          url: el.attr('href'),
          container: '#body',
          timeout: 12000
        });
      }
      else {
        loadPage(el.attr('href'));
      }
    }
  },

  '.disabled': function() {
    return false;
  },

  '.control': function(e) {
  },

  '.restricted': function() {
    if (!isOnline) {
      modal('#modal-login');
      return false;
    }
  },

  '.song-link': function(e, el) {
    mp.playSection(el.parent('section'));
  },

  '.modal': function() {
    modal(e.target.getAttribute('href'));
    return false;
  },

  '.close-modal': function() {
    modal(false);
  },

  '.popup': function(e, el) {
    popup(el);
    return false;
  },

  '.select-on-click': function(e, el) {
    el.select();
  },

  '[data-toggle="hidden"]': function(e, el) {
    $(el.attr('href')).toggleClass('hidden');
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

  '#friends a': function(e, el) {
    e.preventDefault();
    tuneIn(el.attr('id').split('-')[1]);
    return false;
  },

  '#sign-up-button': function(e, el) {
    e.preventDefault();
    registerUser(el);
  },

  '#player-mode': function(e) {
    e.preventDefault();
    updatePlayMode(mp.nextPlayMode());
  },

  '#more-artists': function() {
    var next = $('.artists-shelf li:not(.hidden):lt(5)');
    if (next.length) next.addClass('hidden');
    else $('.artists-shelf li').removeClass('hidden');
  },

  '#nav-shares': function(e, el) {
    el.children('span').remove();
  }
});

// Clicks not on a
body.on('click', function(e) {
  var el = $(e.target);

  spinner.updatePos(e.pageX, e.pageY);

  // Hide dropdowns on click
  if (!el.is('a, input')) navDropdown(false);
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

function pjax(url, container) {
  $.pjax({
    url: url,
    container: container || '#body',
    timeout: 12000
  });
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

      if (dropdown.is('.right-align')) {
        left = left - dropdown.outerWidth()/2 + 45;
      }

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

// Modal
function modal(selector) {
  var modal = $('#modal'),
      show = $('#overlay,#modal');

  if (modalShown || selector === false) {
    if (!modal.children('.permanent').length) {
      show.attr('class', '');
      body.removeClass('modal-shown');
      modalShown = false;
    }
  }
  else {
    modal.html($(selector).clone());
    show.addClass('shown').addClass(selector.substring(1));
    body.addClass('modal-shown');
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

  mp.ffTo(seconds_past);

  if (listen.url.replace(/\?.*/, '') == mp.curPage()) {
    clickSong(listen.song_id);
  } else {
    playAfterLoad = listen.song_id;
    loadPage(listen.url);
  }
}

function loadPage(url, callback) {
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
      } else {
        window.location = button.attr('href');
      }
    },
    error: function(data) {
    }
  })
}

function popup(el) {
  var url = el.attr('href'),
      dimensions = el.data('dimensions').split(',');

  fn.popup(url, dimensions[0], dimensions[1]);
}

$(window).on('gotPageLoad', function(e, data) {
  bindImageErrors(data);
});

bindImageErrors();

function bindImageErrors(context) {
  $('img', context || 'body').error(function imgError() {
    var el = $(this);
    el.attr('error-src', el.attr('src')).attr('src','/images/default.png');
  });
}

function updateBroadcastButton(station_id, song_id) {
  if (isOnline) {
    var i,
        broadcasts = broadcastedIds[station_id],
        broadcast = $('#player-buttons .broadcast').removeClass('remove');

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

$('#player-buttons .broadcast a').click(function() {
  $(this).parent().toggleClass('remove');
})