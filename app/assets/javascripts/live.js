// On page load tune in
if (isTuningIn) {
  tuneIn(tuneInto, function() {
    if (beginListen)
      listenCreatePublish(beginListen);
  });
}

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