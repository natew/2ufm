var spinner = (function() {
  var el = $('#spinner'),
      x,
      y,
      offset = 25,
      options = {
        lines: 6, // The number of lines to draw
        length: 2, // The length of each line
        width: 3, // The line thickness
        radius: 4, // The radius of the inner circle
        corners: 0, // The rounding of the lines
        rotate: 0, // The rotation offset
        color: '#fff', // #rgb or #rrggbb
        speed: 1, // Rounds per second
        trail: 60, // Afterglow percentage
        shadow: true, // Whether to render a shadow
        hwaccel: false, // Whether to use hardware acceleration
        className: 'spinner', // The CSS class to assign to the spinner
        zIndex: 2e9, // The z-index (defaults to 2000000000)
        top: 'auto', // Top position relative to parent in px
        left: 'auto' // Left position relative to parent in px
      };

  return {
    updatePos: function(x, y) {
      x = x;
      y = y;
    },

    attach: function() {
      el
        .spin(options)
        .css({
          left: x + offset,
          top:  y + offset
        })
        .removeClass('hidden');

      $('body').bind('mousemove.spinner', function(e){
        $('#spinner').css({
            left: e.pageX + offset,
            top:  e.pageY + offset
          });
      });
    },

    detach: function() {
      $(document).unbind('mousemove.spinner');
      el.spin(false).addClass('hidden');
    }
  };
}());