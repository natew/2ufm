var pagination = (function(fn, mp) {
  var isLoading = false,
      hasMore = true,
      current = getPage(),
      scrolledTo = current,
      offsets = [],
      w = $(window),
      hasPages = false,
      hasPagination = false;

  function checkNextPage() {
    if (!nearBottom()) return;
    var playlist = $('.playlist:last');

    // Infinite scrolling
    if (hasMore && playlist.length && playlist.is('.has-more')) {
      var link = playlist.next('.next-page').html('Loading...'),
          playlistInfo = playlist.attr('id').split('-');

      var id = playlistInfo[1],
          playlistPage = parseInt(playlistInfo[2], 10);

      isLoading = true;
      current = playlistPage + 1;

      var newPageURL = getNewPageURL(current);

      $.ajax({
        url: newPageURL,
        type: 'get',
        headers: {
          Accept: "text/html+page"
        },
        statusCode: {
          204: function() {
            fn.log('no more pages');
            removeNextPage(link);
            return false;
          }
        },
        success: function(data) {
          scrolledTo = current;
          $(window).trigger('gotPageLoad', data);
          // if (hasPagination) updatePageURL(newPageURL);
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
    return w.scrollTop() >= ($(document).height() - w.height() - 1000);
  }

  function atTop() {
    $.cookie('wasAtTop', true);
    if (current > 1) {
      current = parseInt($('.page-current span').html() || 1, 10);
      updatePageIfNew();
    }
  }

  function notAtTop() {
    $.cookie('wasAtTop', false);
    if (mp.isOnPlayingPage()) {
      current = mp.playingPageNum();
      updatePageIfNew();
    }
    else if (scrolledTo > 1 && current != scrolledTo) {
      current = scrolledTo;
      updatePageIfNew();
    }
  }

  function updatePageIfNew() {
    if (mp.getPage() != window.location.pathname)
      updatePageURL(getNewPageURL(current));
  }

  // Reads URL parameters for ?page=X and returns X
  function getPage() {
    var page = window.location.pathname.match(/p-([0-9]+)/);
    return page ? parseInt(page[1],10) : 1;
  }

  function getNewPageURL(page) {
    var url = mp.getPage(),
        page_path = 'p-' + page,
        page_regex = /p-[0-9]+\/?/,
        hash = window.location.hash;

        fn.log(url)

    // Replace old page
    if (page == 1) {
      url = url.replace(/\/?p-[0-9]+\/?/, '');
    }
    else if (url.match(page_regex)) {
      url = url.replace(page_regex, page_path);
    }
    else {
      if (url.charAt(url.length - 1) == '/') url = url.slice(0, -1);
      url = url + '/' + page_path;
    }

    fn.log(url);

    url += hash;
    return url;
  }

  function updatePageURL(url) {
    fn.log(url);
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
      hasPages = $('.has-more').length > 0;
      hasPagination = $('.pagination').length > 0;
      hasMore = hasPages;
      scrolledTo = 0;
    },

    checkPage: function() {
      if (w.scrollTop() <= 0)
        atTop();
      else {
        notAtTop();
        checkNextPage();
      }
    },

    isLoading: function() {
      return isLoading;
    },

    hasPages: function() {
      return hasPages;
    },

    hasPagination: function() {
      return hasPagination;
    },

    currentPage: function() {
      return current;
    },

    scrolledTo: function() {
      return scrolledTo;
    }
  }
}(fn, mp));

// Automatic page loading
w
  .on('scrollstart', function() {
    if (!pagination.hasPages()) return;
    clearInterval(pageLoadTimeout);
    pageLoadTimeout = setInterval(function() {
      if (!pagination.isLoading()) pagination.checkPage();
    }, 30);
  })
  .on('scrollstop', function() {
    clearInterval(pageLoadTimeout);
    $.cookie('scrollTop', w.scrollTop());
  })
  .on('pagination:restart', function() {
    pagination.restart();
    pagination.updateCurrentPage();
  });