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
  el.toggleClass('live');

  if (el.is('.live')) {
    el.attr('title', 'Turn off live listening').html('On');
  } else {
    el.attr('title', 'Turn on live listening').html('Off');
  }

  $('.tipsy').remove();
  tuneInTip();
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