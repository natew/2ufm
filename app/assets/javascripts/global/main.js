$(document).ready(function() {
  // Path.js
  Path.listen();
  
  // Spinner
  setInterval(rotate, 100);

  $('#query').liveSearch({url: '/search/'});
  
  $('.fav-song').live('click', function() {
    var $this = $(this);
    var $parent = $(this).parent();
    var id = $(this).attr('rel');
    
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
        $parent.html(data);
      },
      error: function() {
        alert('error');
      }
    });
    return false;
  });
});