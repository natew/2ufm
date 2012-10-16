// On page load tune in
if (isTuningIn) {
  tuneIn(tuneInto, function() {
    if (beginListen)
      listenCreatePublish(beginListen);
  });
}

function tuneInTip() {
  $('.tip-e:not(.disabled)').tipsy({gravity: 'e', offset: 5});
}
tuneInTip();

$('#tune-in').click(function() {
  var el = $(this);
  el.toggleClass('live hover-off');
  el.trigger('mouseleave').trigger('mousenter');

  if (el.is('.live')) {
    el.attr('title', 'Turn off live listening').html('On');
  } else {
    el.attr('title', 'Turn on live listening').html('Off');
  }

  $('.tipsy').remove();
  tuneInTip();
});

$('body').on('click', '#friends a', function(e) {
  e.preventDefault();
  tuneIn($(this).attr('id').split('-')[1]);
  return false;
})

// Begin listening to a station
function tuneIn(id, callback) {
  fn.log(id);
  loadPage('/tune/' + id, function() {
    $('body').addClass('live');
    mp.setLive(true);
    doPjax = false;
    if (callback) callback.call();
  });
}

function tuneOut() {
  doPjax = true;
}

function sendAction(action) {
  $.ajax({
    type: 'post',
    url: '/actions',
    data: 'action=' + action
  });
}

// create.js.erb callback for faye
function listenCreatePublish(listen) {
  mp.startedAt(listen.created_at_unix);

  if (mp.isOnPlayingPage()) {
    clickSong(listen.song_id);
  } else {
    loadPage(listen.url, function() {
      clickSong(listen.song_id);
    });
  }
}

function loadPage(url, callback) {
  page.start();
  $.ajax({
    url: url,
    dataType: 'html',
    beforeSend: function(xhr){
      xhr.setRequestHeader('X-PJAX', 'true')
    },
    success: function(data) {
      $('#body').html(data);
      fakeUrl = url;
      page.end();
      if (callback) callback.call();
    }
  });
}

function addShare() {
  setShares(shareCount + 1);
  fn.log(shareCount);
}

function setShares(count) {
  shareCount = parseInt(count,10);
  updateShares();
}

function updateShares() {
  if (shareCount > 0) {
    $('#nav-shares span').remove();
    $('#nav-shares').append('<span>' + shareCount + '</span>');
  }
}

function addSubscriber() {
  fn.log('add subscriber');
  var el = $('#player-live a'),
      count = el.attr('data-count'),
      countInt = parseInt(count, 10) + 1,
      pluralized = countInt === 1 ? ' person listening' : ' people listening';

  $('#player-live').addClass('subscribed');
  el
    .attr('data-count', countInt)
    .html(countInt + pluralized);
}