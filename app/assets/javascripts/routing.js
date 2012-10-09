// Functions relating to moving about pages
// In order of occurence
// enter -> load / error -> exit
var page = {

  start: function pageStart() {
    $('#main-mid .zeroClipboardDiv').remove();
    $('.tipsy').remove();
    fn.attachSpinner();
  },

  end: function pageEnd(data) {
    var curPage = newCurPage || window.location.pathname + window.location.search,
        path = curPage.split('/'),
        tipTimer,
        signedIn = !$('body').is('.signed_out'),
        pageFollow,
        doScrollToTop = true;

    newCurPage = null;
    fn.log(curPage);

    updatePlaylist();
    resetMorePages();
    playAfterRouting();

    // Image errors
    $('.playlist img').on('error', function(){
      var el = $(this);
      el.attr('error-src', el.attr('src')).attr('src','/images/default.png');
    });

    // Update google analytics
    _gaq.push(['_trackPageview', curPage]);

    fn.detachSpinner();

    // Set page in music player && scroll to current section if found
    mp.setPage(curPage, function(foundSection) {
      fn.scrollTo(foundSection);
      doScrollToTop = false;
    });

    // Scroll to top if we are going to new page
    if (doScrollToTop && $('body').scrollTop() > 0)
      fn.scrollToTop();

    // Nav highlight
    setNavActive(curPage);

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
    })

    // Styling for inputs
    $(document).find('#body input').each(function() { $(this).addClass('input-'+$(this).attr('type')); });

    // Disable AJAX stuff signed out
    if (signedIn) {
      $('.remove')
        .live('mouseenter', function() { $('span',this).html('D'); })
        .live('mouseleave', function() { $(this).removeClass('first-hover').find('span').html('2'); });
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