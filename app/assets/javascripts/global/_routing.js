var curPage;

// jQuery and Rails compatability!
// So we can do wants.js but return HTML
$.ajaxSettings.accepts.html = $.ajaxSettings.accepts.script;

// FUNCTIONS

// Lets allow middle clicking for new tabs
var commandPressed = false;
var pressedDisable = function(e) {
    var command = e.metaKey || e.ctrlKey;
    if (command) commandPressed = true;
    else commandPressed = false;
}

// Set active nav tab
function navSetActive(action) {
  $('nav li.active').removeClass('active');
  if (action != null) $('#nav-'+action).parent().addClass('active');
}


// DOCUMENT.READY
$(function() {
  // html5 pushState using Path.js
  Path.history.listen();

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
// enter -> load / error -> exit
var page = {

  enter: function() {
    // Remove tooltips, show loading bar
    $('.tipsy').remove();
    $('#loading').addClass('hide');
  },
  
  load: function(data) {
    // Update google analytics
    //_gaq.push(['_trackPageview', curPage]);
    
    // Set page in music player
    mp.setPage(curPage);
    
    // Update html
    $('#body').html(data);
	  $('#loading').removeClass('hide');

    // Scroll to top if we are going to new page
    if (Path.routes.state == 'push' && $('body').scrollTop() > 0)
      $('html,body').animate({scrollTop:0}, 200);
    
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
        .addClass('disabled');
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

    // Play button on first song
    $doc.find('.playlist section:first-child').addClass('show-play');
    
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
    
    // Image errors
    $('img.cover-medium').error(function(){ $(this).attr('src', '/images/default_medium.jpg'); });
    $('img.cover-small').error(function(){ $(this).attr('src', '/images/default_small.jpg'); });
  },
  
  error: function(xhr) {
    console.log("readyState: "+xhr.readyState+"\nstatus: "+xhr.status);
    console.log("responseText: "+xhr.responseText);
  },
  
  exit: function(xhr,err) {
  },
}

Path.map("/:action(/:id)").to(function(){
  var id  = this.params['id'] ? '/'+this.params['id'] : '';
  curPage = this.params['action']+id;
  navSetActive(this.params['action']);

  // Get the page
  $.ajax({
    type:"GET",
    dataType:"html",
    url: '/'+curPage,
    success: page.load,
    error: page.error
  });
}).enter(page.enter).exit(page.exit);

Path.map("/").to(function(){
  curPage = '/';
  navSetActive(null,null);
  $.ajax({
    type:"GET",
    dataType:"html",
    url: '/home',
    success: page.load,
    error: page.exit
  });
}).enter(page.enter).exit(page.exit);

Path.root("/");