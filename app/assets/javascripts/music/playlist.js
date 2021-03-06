var one_hour = 60 * 60 * 1000,
    one_day = one_hour * 24,
    one_week = one_day * 7,
    months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

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
  $('.not-loaded').removeClass('not-loaded').addClass('loaded');
}

function updateCounts() {
  for (var key in updateBroadcastsCounts) {
    $('#song-' + key).children('.broadcast a').html(updateBroadcastsCounts[key]);
  }
}

function updateTimes() {
  $('.playlist.not-loaded time').each(function() {
    var el = $(this),
        date = new Date(el.attr('datetime')),
        now = new Date;

    if ((now - date) < one_week)
      el.timeago();
    else {
      el.html(months[date.getUTCMonth()] + ' ' + date.getUTCDate() + date.getDaySuffix());
      if (date.getUTCFullYear() > now.getUTCFullYear()) el.html(el.html() + ', ' + date.getUTCFullYear());
    }
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
  fn.log('updating follows', updateFollowsIds);
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

  $('.not-loaded ' + follows)
    .attr('title', f.title)
    .data('method', f.method)
    .removeClass('add')
    .addClass('remove')
    .html('<span>' + f.icon + '</span><strong>' + f.html + '</strong>');

  updateFollowsIds = [];
}