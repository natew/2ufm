var curPage = window.location.pathname;

// Functions relating to moving about pages
// In order of occurence
// enter -> load / error -> exit
var page = {

  start: function() {
    // Remove tooltips, show loading bar
    $('.tipsy').remove();
    $('#loading').addClass('hide');
  },

  end: function(data) {
    fn.log('_routing: page.load()');
    // Update google analytics
    //_gaq.push(['_trackPageview', curPage]);

    $('#loading').removeClass('hide');

    // Set page in music player
    mp.setPage(curPage);

    // Scroll to top if we are going to new page
    if ($('body').scrollTop() > 0)
      $('html,body').animate({scrollTop:0}, 200);

    // Run loaded functions
    var $doc = $(document);
    var $body = $doc.find('body:first');

    // Styling for inputs
    $doc.find('#body input').each(function() { $(this).addClass('input-'+$(this).attr('type')); });

    // Disable AJAX stuff signed out
    if ($body.is('.signed_out'));
    // Signed in
    else {
      $('.remove')
        .live('mouseenter', function() { $('span',this).html('D'); })
        .live('mouseleave', function() { $(this).removeClass('first-hover').find('span').html('2'); });
    }

    // Song heights
    playlistOffset = $('.playlist:first').offset().top;
    songSections = $('.playlist:first section');
    songSections.each(function(index) {
      songOffsets[index] = $(this).offset().top;
    });

    // Highlight first song
    highlightSong();

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

  error: function(xhr) {
    $('#loading').addClass('hide');
    $('#body').addClass('error').html('<h2>'+xhr.status+'</h2>'+'<div id="error">'+xhr.responseText+'</h2>');
  }
}

$('#body')
  .on('pjax:start', page.start)
  .on('pjax:end', page.end)
  .on('pjax:error', page.error);