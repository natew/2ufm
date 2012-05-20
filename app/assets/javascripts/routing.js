// Functions relating to moving about pages
// In order of occurence
// enter -> load / error -> exit
var page = {

  start: function pageStart() {
    // Remove tooltips, show loading bar
    $('.tipsy').remove();
    $('#loading').addClass('rotate');
  },

  end: function pageEnd(data) {
    var curPage = window.location.pathname,
        path = curPage.split('/');
    fn.log(curPage);

    // Update google analytics
    //_gaq.push(['_trackPageview', curPage]);

    $('#loading').removeClass('rotate');

    // Set page in music player
    mp.setPage(curPage);

    // Scroll to top if we are going to new page
    if ($('body').scrollTop() > 0)
      fn.scrollToTop();

    // Run loaded functions
    var $doc = $(document);
    var $body = $doc.find('body:first');

    // Begin tagging
    $('#tags').tagit({
      allowSpaces: true,
      placeholderText: 'What would you like to listen to?'
    });

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

    // Playlist functions
    var playlist = $('.playlist:first');
    if (playlist.length) {
      // Song heights
      var sections = playlist.children('section');
      playlistOffset = playlist.offset().top;
      songSections[0] = sections;
      resetOffsets();
      addOffsets(sections);

      // Highlight first song
      highlightSong();
    }

    // Nav toggle
    var navActive = $('.nav-container a.active'),
        sectionActive = $('.nav-container div.active');

    if (navActive.length) {
      $('.nav-container nav a').click(function(e) {
        navActive.removeClass('active');
        navActive = $(this).addClass('active');
        sectionActive.removeClass('active');
        sectionActive = $($(this).attr('href')).addClass('active');
        return false;
      });
    }

    // Reset page
    scrollPage = 1;
    doneScrolling = false;

    // Stats
    if (path[1] == 'songs') {
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
    }
  },

  error: function(xhr) {
    $('#body').addClass('error').html('<h2>'+xhr.status+'</h2>'+'<div id="error">'+xhr.responseText+'</h2>');
  }
}

$('#body')
  .on('pjax:start', page.start)
  .on('pjax:end', page.end)
  .on('pjax:error', page.error);