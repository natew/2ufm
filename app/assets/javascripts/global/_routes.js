var curPage;

// jQuery and Rails compatability!
// So we can do wants.js but return HTML
$.ajaxSettings.accepts.html = $.ajaxSettings.accepts.script;

// FUNCTIONS

// Lets allow middle clicking for new tabs
var disableHashbang = false;
var pressedDisable = function(e) {
    var command = e.metaKey || e.ctrlKey;
    if (command) disableHashbang = true;
    else disableHashbang = false;
}

// Set active nav tab
function navSetActive(action) {
  $('nav li.active').removeClass('active');
  $('#nav-'+action).parent().addClass('active');
}


// DOCUMENT.READY
$(function() {
  $(window).keydown(pressedDisable).keyup(pressedDisable);
  $(window).blur(pressedDisable); // Prevents bug where alt+tabbing always disabled

  $("a:not(.control)").live('click', function(event) {
    var href = $(this).attr('href');
    if (href[0] == '/' && event.which != 2 && !disableHashbang) {
      event.preventDefault();
      window.location.hash = "#!" + href;
    }
  });

  $('a.disabled').live('click', function(e) {
    // Sign in modal
    return false;
  });
});


// So we can read parameters
function getParameterByName(name) {
  name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
  var regexS = "[\\?&]" + name + "=([^&#]*)";
  var regex = new RegExp(regexS);
  var results = regex.exec(curPage);
  if (results == null) return false;
  else return decodeURIComponent(results[1].replace(/\+/g, " "));
}


// Functions relating to moving about pages
// In order of occurence
// enter -> load -> error -> exit
var page = {

  enter: function() {
    // Remove tooltips
    $('.tipsy').remove();
    
    // Loading...
    $('#body').html('<div id="loading"><span>Loading</span><img src="/images/ajax-loading.gif" /></div>');
    //window.clearInterval(rotate);
    //window.setInterval(rotate, 50);
  },
  
  load: function(data) {
    // Update google analytics
    //_gaq.push(['_trackPageview', curPage]);
    
    // Set page in music player
    mp.setPage(curPage);
    
    // Update html
    $('#body').html(data);    
    
    // Run loaded functions
    var $doc = $(document);
    var $body = $doc.find('body:first');
    
    $doc.find('#body input').each(function() { $(this).addClass('input-'+$(this).attr('type')); });
    
    // Disable AJAX stuff signed out
    if ($body.is('.signed_out')) {
      $doc.find('#body .control.restricted')
        .removeAttr('data-remote')
        .attr('title','Please sign in!')
        .attr('href','#new_user')
        .addClass('disabled')
        .colorbox({inline: true, width: '50%'});
    } else {
      // Signed in
      $('.button.remove').hover(
        function() { $('span',this).html('D'); },
        function() { $('span',this).html('2');
      });
      
      $('.broadcast-song.remove').hover(
        function() { $(this).html('D'); },
        function() { $(this).html('2');
      });
    }
    
    // Listen sharing
    if (getParameterByName('play')) {
      var song = getParameterByName('song');
      var time = getParameterByName('time');
      var section = $('#song-'+song);
      mp.playSection(section);
      $(window).scrollTop(section.offset().top-100);
    }

    // AJAX forms
    if ($doc.find('#wizard').length > 0) {
      $doc.find("#wizard form").ajaxForm({
        type: 'POST',
        success: function() {
          $('h2').html('we did it')
          this.load();
        }
      });
    }
      
    // Stats
    var $stats = $('#stats');
    if ($stats.length > 0) {
      var data = $stats.data('broadcasts');
      
      var options = {
        xaxis: {
          mode: "time",
          minTickSize: [1, "day"],
          min: data[0][0],
          max: data[data.length-1][0]
        }
      }

      $.plot($stats, [data], options);
    }
  },
  
  error: function() {
    alert("readyState: "+xhr.readyState+"\nstatus: "+xhr.status);
    alert("responseText: "+xhr.responseText);
  },
  
  exit: function(xhr,err) {
  },
}

Path.map("#!/:action(/:id)").to(function(){
  var action = '/' + this.params['action'];
  var id     = this.params['id'] ? '/'+this.params['id'] : '' ;
  curPage = action+id;
  
  navSetActive(action);
  $.ajax({
    type:"GET",
    dataType:"html",
    url: curPage,
    success: page.load,
    error: page.error
  });
}).enter(page.enter).exit(page.exit);

Path.map("#!/").to(function(){
  curPage = '/';
  $.ajax({
    type:"GET",
    dataType:"html",
    url: '/',
    success: page.load,
    error: page.exit
  });
}).enter(page.enter).exit(page.exit);

Path.root("#!/home");