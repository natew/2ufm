// Allow middle clicking for new tabs
var commandPressed = false;
var pressedDisable = function(e) {
  console.log('command toggle');
  var command = e.metaKey || e.ctrlKey;
  if (command) commandPressed = true;
  else commandPressed = false;
}

// Sets bar to fixed
function setBarPosition() {
  if ($(window).scrollTop() > 44) $('#bar').addClass('fixed');
  else $('#bar').removeClass('fixed');
}

// Image errors
$('img.cover-medium').error(function(){ $(this).attr('src', '/images/default_medium.jpg'); });
$('img.cover-small').error(function(){ $(this).attr('src', '/images/default_small.jpg'); });

//
// Document.ready
//
$(function() {
  // Fire initial page load
  page.load();

  // HTML5 pushState using Path.js
  Path.history.listen();

  // Disable path.js when command button pressed (allow middle click)
  $(window).keydown(pressedDisable).keyup(pressedDisable);
  $(window).blur(pressedDisable); // Prevents bug where alt+tabbing always disabled

  $("a:not(.control)").live('click', function(event) {
    var href = $(this).attr('href');
    if (href[0] == '/' && event.which != 2 && !commandPressed) {
      event.preventDefault();
      Path.history.pushState({}, "", $(this).attr("href"));
    }
  });

  $('a.disabled').live('click', function(e) {
    // Sign in modal
    return false;
  });

  // Scroll music player
  setBarPosition();
  $(window).scroll(setBarPosition);

  // Bar buttons under logo
  $('#bar-top').click(function(e) {
    e.preventDefault();
    $('html,body').animate({scrollTop:0}, 200);
  });

  // Tooltips
  $(window).scroll(function(){ $('.tipsy').remove() }); // Fucking bugs
  $('.tip-n').tipsy({gravity: 'n', offset: 5, live: true});
  $('.tip').tipsy({gravity: 's', offset: 5, live: true});
  
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
  
  // Modal windows
  /*
  $('.nav a.control').click(function(e) {
    e.preventDefault();
    $('#modal').html($('#' + $(this).data('target')).html());
    $('#overlay').show();
  });*/
    
  
  // Player controls
  // PLAY
  $('#player-play').click(function() {
    mp.toggle();
    return false;
  });
  
  // NEXT
  $('#player-next').click(function() {
    mp.next();
    return false;
  });
  
  // PREV
  $('#player-prev').click(function() {
    mp.prev();
    return false;
  });

  // VOLUME
  $('#player-volume').click(function() {
    mp.volumeToggle();
    return false;
  });
  

  // Play from song
  $('.play-song').live('click',function() {
    var $section = $(this).parent().parent('section');
    if ($section.is('.playing')) {
      mp.pause();
    } else {
      mp.playSection($section);
    }
    return false;
  });
});