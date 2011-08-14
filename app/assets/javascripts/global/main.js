$('input').each(function() { $(this).addClass('input-'+$(this).attr('type')); });

$(document).ready(function() {

  $('#query').liveSearch({url: '/search/'});
});