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

  jQuerize: function(object) {
    for (var key in object) {
      object[key] = $(object[key]);
    }
    return object;
  },

  clipboard: function() {
    var invite = $('#player-invite'),
        text = invite.html(),
        hover = invite.data('hover'),
        click = invite.data('click');

    ZeroClipboard.setMoviePath('/swfs/ZeroClipboard.swf');
    var clip = new ZeroClipboard.Client();
    clip.setHandCursor(true);
    clip.glue('player-invite','player-invite-container');
    clip.setText(document.location.host+invite.attr('href'));
    clip.addEventListener('mouseOver', function (client) {
      invite.trigger('mouseover').html(hover);
    });
    clip.addEventListener('mouseOut', function (client) {
      invite.trigger('mouseout').html(text);
    });
    clip.addEventListener('complete', function(client, text) {
      invite.html(click);
      setTimeout(function() { invite.html(text); }, 2000);
    });
  }
};