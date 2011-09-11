$(document).ready(function() {
  // Path.js
  Path.listen();

  // Header
  $('.tip-n').tipsy({gravity: 'n', offset: 5});
  
  $('#query').liveSearch({url: '/search/'});
  
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
  
  // Username cutoff
  var username = $('#nav-username');
  if (username.length > 0) username.html(fitStringToWidth(username.html(), 110)+ " &darr;");
  
  // Player controls
  // PLAY
  $('#player-controls a.play').click(function() {
    mp.toggle();
    return false;
  });
  
  // NEXT
  $('#player-controls a.next').click(function() {
    mp.next();
    return false;
  });
  
  // PREV
  $('#player-controls a.prev').click(function() {
    mp.prev();
    return false;
  });
  

  // Play from song
  $('a.play-song').live('click',function() {
    var $section = $(this).parent().parent().parent('section');
    if ($section.is('.playing')) {
      mp.stop();
    } else {
      mp.playSection($section);
    }
    return false;
  });
  
  // Broadcast song
  $('.broadcast-song').live('ajax:complete', function(data, status, xhr) {
    $(this).parent().html(data);
  });
});