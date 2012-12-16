// Read URL parameters
var urlParams = {},
    updateParams = (function () {
      function update() {
        var e,
            a = /\+/g,  // Regex for replacing addition symbol with a space
            r = /([^&=]+)=?([^&]*)/g,
            d = function (s) { return decodeURIComponent(s.replace(a, " ")); },
            q = window.location.search.substring(1);

        while (e = r.exec(q))
           urlParams[d(e[1])] = d(e[2]);
      }

      return {
        run: function() {
          update();
        }
      }
    })();

function playFromParams() {
  updateParams.run();
  if (urlParams['play']) {
    var song = urlParams['song'];
    var section = $('#song-' + song);
    if (section.length) mp.playSection(section);
    else mp.playSection($('.playlist:first section:first'));
  }
}

// Hash tag to denote time in songs
if (window.location.hash) {
  var hash = window.location.hash.split('-');
  if (hash[0] == 'song') {
    // TODO time
    mp.playSection($('.playlist section:first'), time[0]*60 + time[1]);
  }
  else if (hash[0] == 'page') {
    // TODO pagination with hash
  }
}