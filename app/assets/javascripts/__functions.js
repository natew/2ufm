DO_LOGGING = true;

String.prototype.leftPad = function (l, c) { return new Array(l - this.length + 1).join(c || ' ') + this; }

var fn = {
  log: function() {
    if (DO_LOGGING)  {
      var caller = arguments.callee.caller ? arguments.callee.caller.name.toString().leftPad(20) : ''.leftPad(20);
      console.log(caller,arguments);
    }
  },

  flatten: function(obj, includePrototype, into, prefix) {
    into = into || {};
    prefix = prefix || "";

    for (var k in obj) {
      if (includePrototype || obj.hasOwnProperty(k)) {
        var prop = obj[k];
        if (prop && typeof prop === "object" &&
          !(prop instanceof Date || prop instanceof RegExp)) {
          fn.flatten(prop, includePrototype, into, prefix + k + "_");
        }
        else {
          into[prefix + k] = prop;
        }
      }
    }
    return into;
  },

  scrollToTop: function() {
    $('html,body').animate({scrollTop:0}, 200);
  },

  jQuerize: function(object) {
    for (var key in object) {
      object[key] = $(object[key]);
    }
    return object;
  },

  clipboard: function(target) {
    var el    = $('#' + target),
        text  = el.html(),
        hover = el.data('hover'),
        click = el.data('click'),
        wait  = false;

    ZeroClipboard.setMoviePath('/swfs/ZeroClipboard.swf');
    var clip = new ZeroClipboard.Client();
    clip.setHandCursor(true);
    clip.glue(target, el.parent().attr('id'));
    clip.setText(document.location.host + el.attr('href'));
    clip.addEventListener('mouseOver', function (client) {
      el.trigger('mouseover').html(hover);
    });
    clip.addEventListener('mouseOut', function (client) {
      if (!wait) el.trigger('mouseout').html(text);
    });
    clip.addEventListener('complete', function(client, clip) {
      el.html(click);
      $('.tipsy').remove();
      wait = true;
      setTimeout(function() { el.html(text); wait = false; }, 2000);
    });
  }
};