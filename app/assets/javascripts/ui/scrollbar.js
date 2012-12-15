(function($){

  $.fn.scrollbar = function(options) {

    var body = $('body');

    this.each(function() {
      var container = $(this),
          ratio,
          disabled,
          handle,
          handle_height,
          container_height,
          scrollbar = $('<div class="scrollbar"><div class="handle"></div></div>');

      scrollbar.insertBefore(container);
      handle = $('.handle:first', container.parent());

      // Calculate content size and ratio inside scrollbar
      container.on('scrollbar:content:changed', function () {
        setTimeout(function() {
          var inner = $('.scroll-inner', container);
          if (!inner.length) {
            fn.log('wrapping', container)
            container.wrapInner('<div class="scroll-inner">');
            inner = $('.scroll-inner', container);

            inner.resize(function() {
              container.trigger('scrollbar:content:changed');
            });
          }

          if (container.height() == container_height) return;
          container_height = container.height();
          fn.log('calculating scrollbars', container_height);

          var inner_height = inner.height();

          handle_height = Math.min(container_height, 180 / (inner_height / container_height));
          handle_height = Math.max(30, handle_height);
          handle.height(handle_height);

          var real_scrollbar_height = container_height - handle_height,
              scrollable_height = inner_height - container_height;

          ratio = scrollable_height / real_scrollbar_height;

          if (!isFinite(ratio) || ratio < 0) {
            scrollbar.addClass('disabled');
            disabled = true;
          } else {
            scrollbar.removeClass('disabled');
            disabled = false;
          }
        }, 0);
      })

      container.trigger('scrollbar:content:changed');

      var handle_position = 0,
          top,
          client_y,
          mousedown;

      // Bind to scroll event
      container.on('scroll', function(e){
        if (mousedown) return;

        var offset  = $(this).scrollTop();
        handle_position = offset / ratio;
        handle.css({ top: handle_position });
      });

      // Click to jump on scrollbar
      scrollbar.on('click', function(e) {
        if (e.target.className === 'handle') return;
        var offset = e.clientY - scrollbar.offset().top - (handle_height / 2);
        container.scrollTop(offset * ratio);
        top = limit_to_container(offset / ratio);
        handle.css({top: top});
        client_y = e.clientY;
      })

      var mousemove_event = function (e) {
        var move = handle_position + e.clientY - client_y;
        top = limit_to_container(move);

        container.scrollTop(top * ratio);
        handle.css({top: top});
      };

      function limit_to_container(move) {
        if (move <= 0) return 0;
        else if (move >= container_height - handle_height)
          return container_height - handle_height;
        else return move;
      }

      // Drag handle
      handle.on('mousedown', function (e) {
        if (disabled) return;

        container.parent().addClass('scrollbar-dragging');
        body.addClass('scrollbar-in-action');
        mousedown = true;

        $(document).on('mouseup', function(e) {
          container.parent().removeClass('scrollbar-dragging');
          body.removeClass('scrollbar-in-action');
          $(document).off('mousemove', mousemove_event);
          handle_position = top;
          mousedown = false;
        });

        client_y = e.clientY;

        $(document).on('mousemove', mousemove_event);
      });
    });

  };

})($)