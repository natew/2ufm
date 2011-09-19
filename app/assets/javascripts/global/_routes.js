// jQuery and Rails compatability!
// So we can do wants.js but return HTML
$.ajaxSettings.accepts.html = $.ajaxSettings.accepts.script;

// Lets allow middle clicking for new tabs
var cmdPressed = false;
$(window).keydown(function(e) {
  if (e.metaKey || e.ctrlKey) {
    cmdPressed = true;
    console.log("pressed");
  } 
}).keyup(function(e) {
  if (!e.metaKey && !e.ctrlKey) {
    cmdPressed = false;
    console.log("unpressed");
  }
});

$("a:not(.control)").live('click', function(event) {
  var href = $(this).attr('href');
  if (href[0] == '/' && event.which != 2 && !cmdPressed) {
    event.preventDefault();
    window.location.hash = "#!" + href;
  }
});

var degrees = 0;
var rotate = function() {
  degrees = degrees+2;
  $('#loading img').rotate(degrees);
}

function navSetActive(action) {
  $('nav li.active').removeClass('active');
  $('#nav-'+action).parent().addClass('active');
}

function pageLoaded() {
  var $doc = $(document);
  $doc.find('#body input').each(function() { $(this).addClass('input-'+$(this).attr('type')); });
  
  // AJAX forms
  $doc.find("#wizard form").ajaxForm({
    type: 'POST',
    success: page.load
  });
}

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
    pageLoaded();
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