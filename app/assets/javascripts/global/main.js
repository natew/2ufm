$(document).ready(function() {
  // Path.js
  Path.listen();
  
  // Spinner
  setInterval(rotate, 100);

  $('#query').liveSearch({url: '/search/'});
  
  // Dropdown menu
  $("body").bind("click", function(e) {
    $("ul.nav-dropdown").hide();
    $('a.nav').parent("li").removeClass("open").children("ul.nav-dropdown").hide();
  });
  
  $("a.nav").click(function(e) {
    var $target = $(this);
    var $parent = $target.parent("li");
    var $siblings = $target.siblings("ul.nav-dropdown");
    var $parentSiblings = $parent.siblings("li");
    if ($parent.hasClass("open")) {
      $parent.removeClass("open");
      $siblings.hide();
    } else {
      $parent.addClass("open");
      $siblings.show();
    }
    $parentSiblings.children("ul.nav-dropdown").hide();
    $parentSiblings.removeClass("open");
    return false;
  });
  
  
  
  // AJAX
  
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