// Functions relating to moving about pages
// In order of occurence
// enter -> load / error -> exit
var page = {

  start: function pageStart() {
    $('.zeroClipboardDiv').remove();
    $('.tipsy').remove();
    fn.attachSpinner();
  },

  end: function pageEnd(data) {
    var curPage = window.location.pathname,
        path = curPage.split('/'),
        tipTimer;

    fn.log(curPage);

    $('img').on('error', function(){ $(this).attr('src','/images/default.png'); });

    // Update google analytics
    //_gaq.push(['_trackPageview', curPage]);

    fn.detachSpinner();

    // Set page in music player
    mp.setPage(curPage);

    // Scroll to top if we are going to new page
    if ($('body').scrollTop() > 0)
      fn.scrollToTop();

    // Run loaded functions
    var $doc = $(document);
    var $body = $doc.children().children('body');

    // Nav highlight
    setNavActive(curPage);

    // Clipboard items
    var citems = $('.clipboard');
    if (citems.length) {
      citems.each(function() { fn.clipboard($(this).attr('id')); });
    }

    // Tooltips
    $('.tooltip').hover(function() {
      clearInterval(tipTimer);
      navDropdown($(this), 6);
    }, function() {
      var tip = $(this),
          target = $(this).attr('data-target');

      tipTimer = setInterval(function() {
        if (!tip.is(':hover') && !$(target).is(':hover')) {
          clearInterval(tipTimer);
          navDropdown(false);
        }
      }, 50);
    })

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

    // Nav toggle
    var navActive = $('.nav-menu a.active'),
        sectionActive = $('.nav-container div.active');

    if (navActive.length) {
      $('.nav-menu a').click(function(e) {
        navActive.removeClass('active');
        navActive = $(this).addClass('active');
        sectionActive.removeClass('active');
        sectionActive = $($(this).attr('href')).addClass('active');
        return false;
      });
    }

    // Reset page
    scrollPage = getPage();
    doneScrolling = false;
  },

  error: function(xhr) {
    $('#body').addClass('error').html('<h2>'+xhr.status+'</h2>'+'<div id="error">'+xhr.responseText+'</h2>');
  }
}

$('#body')
  .on('pjax:start', page.start)
  .on('pjax:end', page.end)
  .on('pjax:error', page.error);