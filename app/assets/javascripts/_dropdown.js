var dropdown = (function() {

})();

// Bind hovering on nav elements
$('.nav-hover').live({
  mouseenter: function(e) {
    if (disableHovers) return;
    var el = $(this),
        hoveredClass = el.attr('class'),
        hovered = navHovered[hoveredClass];

    if (el.is('.hover-off')) return false;

    // fn.log('nav hover.. hovered?', hoveredClass, hovered, el);
    clearInterval(navHoverInterval);
    closeHoveredDropdown();
    if (!hovered) {
      navHoverActive = el;
      navDropdown(el, false, true);
      navHovered[hoveredClass] = true;
    }
  },
  mouseleave: function() {
    navHoverInterval = setInterval(function() {
      closeHoveredDropdown();
    }, 250);
  }
});

function closeHoveredDropdown(force) {
  var el = navHoverActive,
      force = force || false;

  // fn.log(el, force);

  if (el && (force || ( !el.is(':hover') && !$((el.attr('data-target') || el.attr('href'))).is(':hover') ) ) ) {
    navUnhoveredOnce = true;
    if (navUnhoveredOnce) {
      navDropdown(false);
      clearInterval(navHoverInterval);
      navHovered[el.attr('class')] = false;
      navUnhoveredOnce = false;
    }
  }
}

function navDropdown(nav, pad, hover) {
  var delay = hover ? 100 : 0,
      attrDelay = nav ? parseInt(nav.attr('data-delay') || 0, 10) : false,
      delay = attrDelay || delay;

  // fn.log(nav, 'open?', navOpen, 'delay', delay);

  setTimeout(function() {
    if (nav && nav.length) {
      // fn.log(nav, pad, 'class=', nav.attr('class'));
      if (hover && !nav.is(':hover')) return false;
      if (nav.is('.song-share')) updateShare(nav);

      var pad = pad ? pad : parseInt(nav.attr('data-pad'), 10),
          padding = pad ? pad : 10,
          target = nav.attr('href')[0] == '#' ? nav.attr('href') : nav.attr('data-target'),
          dropdown = $(target).removeClass('hidden').addClass('open'),
          top = nav.offset().top - doc.scrollTop() + nav.height() + padding,
          left = Math.floor(nav.offset().left + (nav.outerWidth()/2) - (dropdown.width()/2));

          fn.log(left, left + dropdown.width(), w.width())

      if (left < 4) {
        left = 4;
      }
      else if (left + dropdown.width() + 12 > w.width()) {
        left = w.width() - dropdown.width() - 12;
      }

      // If the nav is not already open
      if (!(navOpen && navOpen[0] == dropdown[0])) {
        navOpen = dropdown.css({
          top: top,
          left: left
        });

        if (nav.is('.update-clipboard')) {
          fn.clipboard('share-link', 'relative');
        }

        return true;
      }
    }

    if (navOpen) navOpen.removeClass('open').addClass('hidden');
    navOpen = false;
  }, delay);
}
