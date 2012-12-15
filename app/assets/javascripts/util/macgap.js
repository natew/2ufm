// Mac app download
// if (navigator.appVersion.indexOf("Mac") != -1) {
//   $('#sidebar .announce').addClass('ismac');
// }

//
// Application integration
//
if (typeof macgap !== 'undefined') {
  document.addEventListener('play', function() {
    mp.toggle();
    showGrowlInfo();
  }, true);
  document.addEventListener('prev', function() {
    mp.prev();
    showGrowlInfo();
  }, true);
  document.addEventListener('next', function() {
    mp.next();
    showGrowlInfo();
  }, true);

  function showGrowlInfo() {
    var info = mp.curSongInfo();
    macgap.growl.notify({title: info.artist_name + " - " + info.name, content: 'Now playing'});
  }
}