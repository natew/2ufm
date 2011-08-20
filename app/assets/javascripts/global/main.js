$(document).ready(function() {
  // Path.js
  Path.listen();
  
  // Spinner
  setInterval(rotate, 100);

  $('#query').liveSearch({url: '/search/'});
  
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