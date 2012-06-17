var commandPressed = false;

// Allow middle clicking for new tabs
function disableCommand(e) {
  commandPressed = false;
}

function keyDown(e) {
  if (e.target.tagName.match(/input|textarea|button/i)) {
    return;
  }

  if (e.metaKey || e.ctrlKey) {
    commandPressed = true;
    return;
  }

  fn.log('Key pressed ', e.which);
  switch(e.keyCode) {
    // Left
    case 37:
      mp.prev();
      e.preventDefault();
      break;
    // Right
    case 39:
      mp.next();
      e.preventDefault();
      break;
    // Space
    case 32:
      if (mp.isPlaying()) mp.toggle();
      else mp.playSection(highlightedSong);
      e.preventDefault();
      break;
    // Enter
    case 13:
      if (mp.isPlaying()
        && mp.getSection().attr('id') == highlightedSong.attr('id')) mp.toggle();
      else mp.playSection(highlightedSong);
      break;
    // Esc
    case 27:
      modal();
      break;
  }
}

function keyUp(e) {
  if (e.metaKey || e.ctrlKey) {
    commandPressed = false;
  } else {
    switch(e.keyCode) {
    }
  }
}

$(window).keydown(keyDown).keyup(keyUp).blur(disableCommand);