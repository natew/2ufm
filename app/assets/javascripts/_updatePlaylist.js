function updatePlaylist() {
  fn.log('Updating, isOnline?', isOnline);

  if (isOnline) {
    updateFollows();
    updateBroadcasts();
    updateListens();
    updateFriendBroadcasts();

    if (isAdmin) {
      $('.playlist.not-loaded section').each(function() {
        var id = $(this).attr('id').split('-')[1];
        $('.song-controls', this).append('<a class="no-external control" download="'+id+'.mp3" href="http://media.2u.fm/song_files/' + id + '_original.mp3">DL</a>');
      })
    }
  }
  updateTimes();
  updateCounts();
  $('.playlist.not-loaded').removeClass('not-loaded').addClass('loaded');
}

function updateCounts() {
  for (var key in updateBroadcastsCounts) {
    $('#song-' + key).children('.song-meta').find('.song-controls .broadcast a').html(updateBroadcastsCounts[key]);
  }
}

function updateTimes() {
  $('.playlist.not-loaded time').each(function() {
    fn.log($(this).attr('datetime'));
    var el = $(this),
        datetime = new Date(el.attr('datetime') * 1000).toRelativeTime();
    el.html(datetime);
  });
}

function updateListens() {
  if (!updateListensIds) return false;
  for(var key in updateListensIds) {
    $('#song-' + key).addClass('listened-to').attr('data-listen', updateListensIds[key]);
  }
}

function updateBroadcasts() {
  if (!updateBroadcastsIds || updateBroadcastsIds.length == 0) return false;
  var select = '#song-',
      songs = select + updateBroadcastsIds.join(',' + select);

  $(songs).each(function() {
    var broadcast = $(this).addClass('liked').children('.broadcast').children('a');
    broadcast
      .data('method', 'delete')
      .removeClass('add')
      .addClass('remove');
  });
}

function updateFriendBroadcasts() {
  if (typeof(updateFriendBroadcastIds) === 'undefined') return false;
  for (var sid in updateFriendBroadcastIds) {
    $('#song-' + sid + ' .broadcast a').attr('title', 'Liked by ' + updateFriendBroadcastIds[sid]);
  }
}

function updateFollows() {
  updateFollowsIds = fn.flattenArray(updateFollowsIds);
  if (!updateFollowsIds || updateFollowsIds.length == 0) return false;
  var follows, f = {
        icon: '2',
        html: 'Following',
        title: 'Unfollow station',
        method: 'delete'
      };

  if (updateFollowsIds.length > 1) {
    follows = '.follow-' + updateFollowsIds.join(' a, .follow-') + ' a';
  } else {
    follows = '.follow-' + updateFollowsIds[0] + ' a';
  }

  $('.playlist.not-loaded ' + follows)
    .attr('title', f.title)
    .data('method', f.method)
    .removeClass('add')
    .addClass('remove')
    .html('<span>' + f.icon + '</span><strong>' + f.html + '</strong>');

  updateFollowsIds = [];
}