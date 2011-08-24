// jQuery and Rails compatability!
// So we can do wants.js but return HTML
$.ajaxSettings.accepts.html = $.ajaxSettings.accepts.script;

$("a:not(.control)").live("click", function(event){
  var href = $(this).attr("href");
  if(href[0] == "/"){
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
  $('nav:first a').removeClass('active').filter('#nav-'+action).addClass('active');
}

// Functions relating to moving about pages
// In order of occurence
// enter -> load -> error -> exit
var page = {
  enter: function() {
    // Update google analytics
    //_gaq.push(['_trackPageview', document.location.href]);
    
    // Loading...
    $('#body').html('<div id="loading"><img src="/images/loading.png" /><h2>Loading</h2></div>');
    window.clearInterval(rotate);
    window.setInterval(rotate, 50);
  },
  
  load: function(data) {
    $('#body').html(data);
    $(document).find('#body input').each(function() { $(this).addClass('input-'+$(this).attr('type')); });
  },
  
  error: function() {
    alert("readyState: "+xhr.readyState+"\nstatus: "+xhr.status);
    alert("responseText: "+xhr.responseText);
  },
  
  exit: function(xhr,err) {
    window.clearInterval(rotate);
    degrees = 0;
  }
}

Path.map("#!/:action/:id").to(function(){
  var action = this.params['action'];
  var id = this.params['id'];
  navSetActive(action);
  $.ajax({
    type:"GET",
    dataType:"html",
    url: '/' + action + "/" + id,
    success: page.load,
    error: page.error
  });
}).enter(page.enter).exit(page.exit);

Path.map("#!/:action").to(function(){
  var action = this.params['action'];
  navSetActive(action);
  $.ajax({
    type:"GET",
    dataType:"html",
    url: '/' + action,
    success: page.load,
    error: page.exit
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

Path.root("/loading");