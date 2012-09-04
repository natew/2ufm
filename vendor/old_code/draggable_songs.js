
var last, el, friendHovered = false;

// Dragging to friends
if (isOnline) {
  $('.playlist-song section').on('mousedown', function songMouseDown(e) {
    e.preventDefault(e);
    shareSong = $(this).attr('id').split('-')[1];
    mouseDown = true;

    $(document).bind('mousemove', function songMouseMove(e) {
      if (mouseDown) {
        e.preventDefault();
        updatePosition(e);

        // Prevent load
        var now = new Date();
        if (now - last < 35) return;
        last = now;

        // Show dragger
        if (!isDragging) $('#song-dragger').addClass('visible');
        isDragging = true;

        // Show hovered friend
        el = $(document.elementFromPoint(e.clientX, e.clientY));

        // Highlight friend
        if (el.is('#stations-inner a')) el.addClass('active');
        else $('#stations-inner a').removeClass('active');
      }
    }).on('mouseup', function songMouseUp() {
      mouseDown = false;
      if (isDragging) {
        $('#song-dragger').removeClass('visible');
        var receiver = $('#stations-inner a.active');
        $('#stations-inner a').removeClass('active');
        $(document).unbind('mousemove');
        isDragging = false;

        // Send song
        el = $(document.elementFromPoint(e.clientX, e.clientY));
        fn.log(el, el.length && el.is('.song-link'));
        if (el.length && el.is('.song-link')) {
          var data = {
            'receiver': receiver.attr('id').split('-')[1],
            'song': shareSong,
          };

          fn.log(data);
          $.post('/share', data, function() {
            notice('Sent song to ' + receiver.html(), 2);
          })
        }
      }
    });

    function updatePosition(e) {
      var x = parseInt(e.clientX, 10),
          y = parseInt(e.clientY, 10);

      $('#song-dragger').css({
        top: y,
        left: x
      });
    }
  });
}