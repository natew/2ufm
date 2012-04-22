// Variables
var jwindow = $(window);

// Sets bar to fixed
var setBarPosition = function() {
  if ($(window).scrollTop() > 44) $('#bar').addClass('fixed');
  else $('#bar').removeClass('fixed');
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

  // Scroll music player
  setBarPosition();
  jwindow.scroll(setBarPosition);

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
  jwindow.scroll(function(){ $('.tipsy').remove() }); // Fucking bugs
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
  $('body').on('click', function(e) {
    $('.nav-dropdown').hide();
    $('.nav a').parent('div').removeClass('open').children('div.nav-dropdown').hide();
  });

  $('#nav-username').click(function(e) {
    e.preventDefault();
    var $target = $(this);
    var $parent = $target.parent('div');
    var $siblings = $parent.siblings('div.nav-dropdown');
    if ($parent.hasClass('open')) {
      $parent.removeClass('open');
      $siblings.hide();
    } else {
      $parent.addClass('open');
      $siblings.show();
    }
  });

  // Player controls
  mpClick('#player-play', 'toggle');
  mpClick('#player-next', 'next');
  mpClick('#player-prev', 'prev');
  mpClick('#player-volume', 'volumeToggle');

  // Play from song
  fn.log('binding song clicks');
  $('.song-link').on('click',function songClick(e) {
    e.preventDefault();
    var section = $(this).parent();
    fn.log(section);
    section.is('.playing') ? mp.pause() : mp.playSection(section);
  });
});