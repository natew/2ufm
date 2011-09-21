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
    console.log("disable hashbang = " + disableHashbang);
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
    e.preventDefault();
  });
});


// Functions relating to moving about pages
// In order of occurence
// enter -> load -> error -> exit
var page = {

  enter: function() {
    // Update google analytics
    //_gaq.push(['_trackPageview', document.location.href]);
    
    // Remove tooltips
    $('.tipsy').remove();
    
    // Loading...
    $('#body').html('<div id="loading"><span>Loading</span><img src="/images/ajax-loading.gif" /></div>');
    //window.clearInterval(rotate);
    //window.setInterval(rotate, 50);
  },
  
  load: function(data) {
    // Set page in music player
    mp.setPage(document.location.href);
    
    // Update html
    $('#body').html(data);    
    
    // Run loaded functions
    var $doc = $(document);
    var $body = $doc.find('body:first');
    
    $doc.find('#body input').each(function() { $(this).addClass('input-'+$(this).attr('type')); });
    
    if ($body.is('.signed_out')) {
      $doc.find('#body .control')
        .removeAttr('data-remote')
        .attr('title','Please sign in!')
        .addClass('disabled');
    }

    // AJAX forms
    if ($body.is('.wizard')) {
      $doc.find("#wizard form").ajaxForm({
        type: 'POST',
        success: page.load
      });
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
  
  navSetActive(action);
  $.ajax({
    type:"GET",
    dataType:"html",
    url: action + id,
    success: page.load,
    error: page.error
  });
}).enter(page.enter).exit(page.exit);

Path.map("#!/").to(function(){
  $.ajax({
    type:"GET",
    dataType:"html",
    url: '/',
    success: page.load,
    error: page.exit
  });
}).enter(page.enter).exit(page.exit);

Path.root("#!/home");