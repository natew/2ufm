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
var rotate = function(){
  degrees = degrees+2;
  $('#loading img').rotate(degrees);
}

function pageLoadTransition() {
  // Update google analytics
  //_gaq.push(['_trackPageview', document.location.href]);
  
  // Loading...
  $('#body').html('<div id="loading"><img src="/images/loading.png" /><h2>Loading...</h2></div>');
  window.clearInterval(rotate);
  window.setInterval(rotate, 50);
}

function pageError(xhr,err){
    alert("readyState: "+xhr.readyState+"\nstatus: "+xhr.status);
    alert("responseText: "+xhr.responseText);
}

function loadPage(data) {
  $('#body').html(data);
  $('#body input').each(function() { $(this).addClass('input-'+$(this).attr('type')); });
  window.clearInterval(rotate);
  degrees = 0;
}

Path.map("#!/:page/:id").to(function(){
  var page = this.params['page'];
  var id = this.params['id'];
  $.ajax({
    type:"GET",
    dataType:"html",
    url: '/' + page + "/" + id,
    success: loadPage,
    error:pageError
  });
}).enter(pageLoadTransition);

Path.map("#!/:page").to(function(){
  var page = this.params['page'];
  $.ajax({
    type:"GET",
    dataType:"html",
    url: '/' + page,
    success: loadPage,
    error:pageError
  });
}).enter(pageLoadTransition);