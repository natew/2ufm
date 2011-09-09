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
  
  // Favorite song
  $('.fav-song').live('click', function() {
    var $this = $(this);
    var $parent = $(this).parent().parent();
    var id = $this.attr('rel');
    
    if ($this.is('.remove')) {
      var action = '/' + id;
      var data = '';
      var type = 'DELETE';
    } else {
      var action = '';
      var data = 'id=' + id;
      var type = 'POST';
    }
    
    $.ajax({
      type: type,
      dataType: "html",
      data: data,
      url: '/favorites' + action,
      success: function(data) {
        $parent.remove('.fav-count,.fav-control');
        $parent.append(data);
      },
      error: function() {
        alert('error');
      }
    });
    return false;
  });
  
  // Favorite station
  $('.station-favorite').live('click', function() {
    var $this = $(this);
    var $parent = $(this).parent();
    var id = $this.attr('rel');
    
    if ($this.is('.remove')) {
      var action = '/' + id;
      var data = 'type=station';
      var type = 'DELETE';
    } else {
      var action = '';
      var data = 'id=' + id + 'type=station';
      var type = 'POST';
    }
    
    $.ajax({
      type: type,
      dataType: "html",
      data: data,
      url: '/favorites' + action,
      success: function(data) {
        $parent.prepend(data);
      },
      error: function() {
        alert('error');
      }
    });
    return false;
  });
  
  // Favorite blog
  $('.blog-favorite').live('click', function() {
    var $this = $(this);
    var $parent = $(this).parent();
    var id = $this.attr('rel');
    
    if ($this.is('.remove')) {
      var action = '/' + id;
      var data = 'type=blog';
      var type = 'DELETE';
    } else {
      var action = '';
      var data = 'id=' + id + '&type=blog';
      var type = 'POST';
    }
    
    $.ajax({
      type: type,
      dataType: "html",
      data: data,
      url: '/favorites' + action,
      success: function(data) {
        $parent.prepend(data);
      },
      error: function() {
        alert('error');
      }
    });
    return false;
  });
});