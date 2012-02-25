$(function() {
  var $bar       = $('#bar'),
      $window    = $(window);

  // Scroll music player
  $window.scroll(function() {
    if ($window.scrollTop() > 44) $bar.addClass('fixed');
    else $bar.removeClass('fixed');
  });

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
  $('#player-buttons a.play').click(function() {
    mp.toggle();
    return false;
  });
  
  // NEXT
  $('#player-buttons a.next').click(function() {
    mp.next();
    return false;
  });
  
  // PREV
  $('#player-buttons a.prev').click(function() {
    mp.prev();
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