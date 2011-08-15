$(document).ready(function() {
  // Path.js
  Path.listen();
  
  // Spinner
  setInterval(rotate, 100);

  $('#query').liveSearch({url: '/search/'});
});