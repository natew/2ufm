var tune = (function(mp) {
  var tunedIn = false,
      userId,
      tuneButton = $('#tune-in');

  var tuner = {
    start: function(id, beginListen) {
      fn.log(id);
      loadPage('/tune/' + id, function() {
        $('body').addClass('live');
        mp.setLive(true);
        doPjax = false;
        goToListen(beginListen);
      });
    },

    stop: function() {
      $('body').removeClass('live');
      tunedIn = false;
    },

    turnOn: function() {
      tuneButton.attr('title', 'Stop broadcasting').html('On');
    },

    turnOff: function() {
      tuneButton.attr('title', 'Start broadcasting').html('Off');
      tuner.stop();
    },

    toggleOn: function() {
      tuneButton.toggleClass('live hover-off');
      closeHoveredDropdown(true);
      tuneButton.trigger('mouseenter');

      tuneButton.is('.live') ? this.turnOn() : this.turnOff();

      $('.tipsy').remove();
    }
  }

  return {
    into: function(id, beginListen) {
      tuner.start(id, beginListen);
    },

    out: function() {
      tuner.stop();
    },

    live: function() {
      return tunedIn;
    },

    toggleOn: function() {
      tuner.toggleOn();
    }
  }
})(mp);

function tuneIn() {
  tune.into(tuneInto, beginListen);
}

// On page load tune in
if (isTuningIn) {
  tuneIn();
}

$('body').on('click', '#friends a', function(e) {
  e.preventDefault();
  tune.into($(this).attr('id').split('-')[1]);
});

tune.toggleOn();
$('#tune-in').click(function() {
  tune.toggleOn();
});


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
  shareCount++;
  updateShares();
  fn.log(shareCount);
}

function updateShares(count) {
  if (typeof count === 'number') shareCount = count;

  if (shareCount > 0) {
    notice('New song in your inbox');
    $('.notifications').html(shareCount);
  }

  $('.notifications').toggleClass('greater-than-zero', shareCount > 0);
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

function goToListen(listen) {
  if (!listen) return false;

  if (mp.isOnPlayingPage())
    clickSong(listen.song_id);
  else {
    loadPage(listen.url, function() {
      clickSong(listen.song_id);
    });
  }
}