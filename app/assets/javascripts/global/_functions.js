var fn = {
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
    ZeroClipboard.setMoviePath('/swfs/ZeroClipboard.swf');
    var clip = new ZeroClipboard.Client();
    clip.setHandCursor(true);
    clip.glue('invite','player-shortcode');
    clip.setText(document.location.host+$('#invite').attr('href'));
    clip.addEventListener('mouseOver', function (client) {
      $('#invite').trigger('mouseover').html('Copy link!');
    });
    clip.addEventListener('mouseOut', function (client) {
      $('#invite').trigger('mouseout').html('&laquo; Invite friends!');
    });
    clip.addEventListener('complete', function(client, text) {
      var $invite = $('#invite');
      var html = $invite.html();
      $invite.html('Copied!')
      setTimeout(function() { $invite.html(html); }, 2000);
    });
  }
};