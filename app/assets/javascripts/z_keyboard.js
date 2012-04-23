var commandPressed = false;

// Allow middle clicking for new tabs
function disableCommand(e) {
  commandPressed = false;
}

function keyDown(e) {
  if (e.metaKey || e.ctrlKey) {
    commandPressed = true;
  } else {
    var run = false;
    fn.log('Key pressed ', e.which);
    switch(e.keyCode) {
      // Left
      case 37:
        mp.prev();
        run = true;
        break;
      // Right
      case 39:
        mp.next();
        run = true;
        break;
      // Space
      case 32:
        mp.toggle();
        run = true;
        break;
      // Enter
      case 13:
        mp.playSection(highlightedSong);
        break;
    }

    if (run) e.preventDefault();
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