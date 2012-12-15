// Functions relating to moving about pages
// In order of occurence
// enter -> load / error -> exit
var page = {

  start: function pageStart() {
    $('.zeroClipboardDiv').remove();
    $('.tipsy').remove();
    spinner.attach();
  },

  end: function pageEnd() {
    var curPage = fakeUrl || window.location.pathname + window.location.search,
        path = curPage.split('/'),
        tipTimer,
        pageFollow,
        doScrollToTop = true,
        pageIdentifier = $('#page-identifier');

    fn.log(curPage, pageIdentifier.attr('class'));

    if (doPageEvents) pageEvents();

    // Nav highlight
    setNavActive(curPage);

    doPlaysActions();
    w.trigger('pagination:restart');
    updatePlaylist();
    spinner.detach();
    bindImageErrors();
    mp.hasMoved(false);
    setupFixedTitles();
    bindDataRemoteEvents();

    // Update google analytics
    _gaq.push(['_trackPageview', curPage]);

    // Update page title
    if (!mp.isLoaded()) {
      $('title').html($('#title').html());
    }

    // Set page in music player && scroll to current section if found
    mp.setPage(curPage, function(foundSection) {
      scrollToPlayingSong(foundSection);
      doScrollToTop = false;
    });

    // Scroll to top if we are going to new page
    if (doScrollToTop && $('body').scrollTop() > 0)
      fn.scrollToTop();

    // Live listen tune in
    if (pageIdentifier.is('.action-live')) {
      tuneIn();
    }

    // Clipboard items
    var citems = $('#main-mid .clipboard');
    if (citems.length) {
      fn.log('binding to clipboard');
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
    });

    // Styling for inputs
    $(document).find('#body input').each(function() { $(this).addClass('input-'+$(this).attr('type')); });

    // Update notifications
    if (curPage == "/shares/inbox") {
      updateShares(0);
    }
  },

  error: function pageError(e, text) {
    fn.replaceState(nextUrl);
    $('#body').html(text.responseText);
    return false;
  },

  timeout: function() {
    return false;
  }
}

body
  .on('pjax:start', page.start)
  .on('pjax:end', page.end)
  .on('pjax:error', page.error)
  .on('pjax:timeout', page.timeout);