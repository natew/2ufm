var pagination = (function(fn, mp) {
  var pageLoadTimeout,
      isLoading = false,
      hasMore = true,
      current = getPage(),
      offsets = [];

  $(window).scroll(function() {
    // Automatic page loading
    if (!isLoading) {
      clearTimeout(pageLoadTimeout);
      pageLoadTimeout = setTimeout(function() {
        if (nearBottom()) {
          var lastPlaylist = $('.playlist:visible:last');
          if (lastPlaylist.length && lastPlaylist.is('.has-more'))
            nextPage(lastPlaylist);
        }
      }, 10);
    }
  });

  function nextPage(playlist) {
    // Infinite scrolling
    if (hasMore && playlist) {
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

      $.ajax({
        url: mp.getPage(),
        type: 'get',
        data: 'i=' + id + '&p=' + (playlistPage + 1),
        headers: {
          Accept: "text/page; charset=utf-8",
          "Content-Type": "text/page; charset=utf-8"
        },
        statusCode: {
          204: function() {
            removeNextPage(link);
            return false;
          }
        },
        success: function(data) {
          current = playlistPage + 1;
          var playlist = $('#playlist-' + id + '-' + current);
          link.html('Page ' + current).addClass('loaded');
          isLoading = false;
          link.after(data);
          updatePageURL(current);
          $(window).trigger('pageLoaded');
        },
        error: function() {
          removeNextPage(link);
        }
      })
    }
  }

  function nearBottom() {
    return w.scrollTop() >= ($(document).height() - $(window).height() - 1200);
  }

  // Reads URL parameters for ?page=X and returns X
  function getPage() {
    var page = window.location.search.match(/p=([0-9]+)/);
    return page ? parseInt(page[1],10) : 1;
  }

  function updatePageURL(page) {
    var url = mp.getPage(),
        page = 'p=' + page,
        page_regex = /p=[0-9]+/,
        hash = window.location.hash;

    // Replace old page
    if (url.match(page_regex)) {
      url = url.replace(page_regex, page);
    } else {
      url += url.match(/\?/) ? '&' + page : '?' + page;
    }

    url += hash;
    fn.replaceState(url);
    mp.updatePage(url);
  }

  function resetMorePages() {
    hasMore = true;
  }

  function removeNextPage(link) {
    hasMore = false;
    link.remove();
  }

  return {
    updateCurrentPage: function() {
      current = getPage();
    },

    resetMorePages: function() {
      resetMorePages();
    }
  }
}(fn, mp));