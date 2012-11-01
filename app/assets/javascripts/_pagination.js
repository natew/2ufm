var pagination = (function(fn, mp) {
  var isLoading = false,
      hasMore = true,
      current = getPage(),
      offsets = [];

  function nextPage() {
    if (!nearBottom()) return;
    var playlist = $('.playlist:visible:last');

    // Infinite scrolling
    if (hasMore && playlist.length && playlist.is('.has-more')) {
      var link = playlist.next('.next-page').html('Loading...'),
          playlistInfo = playlist.attr('id').split('-');

      // Support negative numbers
      if (playlistInfo.length == 4) {
        playlistInfo.shift();
        playlistInfo[1] = '-' + playlistInfo[1];
      }

      var id = playlistInfo[1],
          playlistPage = parseInt(playlistInfo[2], 10);

      isLoading = true;
      current = playlistPage + 1;

      var newPageURL = getNewPageURL(current);

      $.ajax({
        url: newPageURL,
        type: 'get',
        headers: {
          Accept: "text/page"
        },
        statusCode: {
          204: function() {
            fn.log('no more pages');
            removeNextPage(link);
            return false;
          }
        },
        success: function(data) {
          $(window).trigger('gotPageLoad', data);
          updatePageURL(newPageURL);
          var playlist = $('#playlist-' + id + '-' + current);
          link.html('Page ' + current).addClass('loaded');
          isLoading = false;
          bindImageErrors(data);
          link.after(data);
          $(window).trigger('pageLoaded');
        },
        error: function() {
          playlist.addClass('load-page-error');
          isLoading = false;
          hasMore = false;
          link.html('Error loading next page');
        }
      })
    }
  }

  function nearBottom() {
    return $(window).scrollTop() >= ($(document).height() - $(window).height() - 1200);
  }

  // Reads URL parameters for ?page=X and returns X
  function getPage() {
    var page = window.location.pathname.match(/p-([0-9]+)/);
    return page ? parseInt(page[1],10) : 1;
  }

  function getNewPageURL(page) {
    var url = mp.getPage(),
        page = 'p-' + page,
        page_regex = /p-[0-9]+/,
        hash = window.location.hash;

    // Replace old page
    if (url.match(page_regex)) {
      url = url.replace(page_regex, page);
    } else {
      if (url == '/') url = '';
      url = url + '/' + page;
    }

    fn.log(url);

    url += hash;
    return url;
  }

  function updatePageURL(url) {
    fn.replaceState(url);
    mp.updatePage(url);
  }

  function removeNextPage(link) {
    hasMore = false;
    link.remove();
  }

  return {
    updateCurrentPage: function() {
      current = getPage();
    },

    restart: function() {
      hasMore = true;
    },

    loadNext: function() {
      nextPage();
    },

    isLoading: function() {
      return isLoading;
    },

    currentPage: function() {
      return current;
    }
  }
}(fn, mp));

w.scroll(function() {
  // Automatic page loading
  if (!pagination.isLoading()) {
    clearTimeout(pageLoadTimeout);
    pageLoadTimeout = setTimeout(function() {
      pagination.loadNext();
    }, 10);
  }
});