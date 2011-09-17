$(document).ready(function() {
  // Path.js
  Path.listen();

  // Tooltips
  $('.tip-n').tipsy({gravity: 'n', offset: 5});
  $('.tip').tipsy({gravity: 's', offset: 5, live: true});
  
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