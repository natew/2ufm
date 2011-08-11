// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require_tree ./global

soundManager.url = '/swfs/soundmanager2_debug.swf';
soundManager.flashVersion = 9; // optional: shiny features (default = 8)
soundManager.useFlashBlock = false; // optionally, enable when you're ready to dive in
/*
 * read up on HTML5 audio support, if you're feeling adventurous.
 * iPad/iPhone and devices without flash installed will always attempt to use it.
*/
soundManager.onready(function(){

  // SM2 has loaded - now you can create and play sounds!

  var mySound = soundManager.createSound({
    id: 'aSound',
    url: '/path/to/an.mp3'
    // onload: myOnloadHandler,
    // other options here..
  });

  //mySound.play();

});