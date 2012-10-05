DO_LOGGING = true;

String.prototype.leftPad = function (l, c) { return new Array(l - this.length + 1).join(c || ' ') + this; }

// Spinner options
var lastPosition = [0, 0],
    offset = 25,
    spinner = $('#spinner'),
    spinOpts = {
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


var fn = {
  log: function() {
    if (DO_LOGGING)  {
      var caller = arguments.callee.caller ? arguments.callee.caller.name.toString().leftPad(20) : ''.leftPad(20);
      console.log(caller,arguments);
    }
  },

  pad: function(number, length) {
    var str = '' + number;
    while (str.length < length) {
        str = '0' + str;
    }
    return str;
  },

  triggerOnFinish: function(func , timeout) {
     var timeoutID , timeout = timeout || 200;
     return function () {
        var scope = this , args = arguments;
        clearTimeout( timeoutID );
        timeoutID = setTimeout( function () {
            func.apply( scope , Array.prototype.slice.call( args ) );
        } , timeout );
     }
  },


  popup: function(url, width, height) {
    var left = (screen.width/2)-(width/2),
        top = (screen.height/2)-(height/2),
        newwindow = window.open(url, 'name', 'menubar=no,toolbar=no,status=no,width='+width+',height='+height+',left='+left+',top='+top);
    if (window.focus) newwindow.focus();
    return newwindow;
  },

  replaceState: function(url, container) {
    return window.history.replaceState(null,document.title,url);;
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

  capitalize: function(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
  },

  scrollToTop: function() {
    $('html,body').animate({scrollTop:0}, 200);
  },

  scrollTo: function(object) {
    var top = object;
    if (typeof object != 'number') top = object.offset().top - 100;

    $('html,body').animate({scrollTop: top }, 100);
  },

  jQuerize: function(object) {
    for (var key in object) {
      object[key] = $(object[key]);
    }
    return object;
  },

  validateEmail: function(email) {
    var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email);
  },

  clipboard: function fnClipboard(target, position) {
    fn.log('clipboard', target);
    var el    = $('#' + target),
        text  = el.html(),
        hover = el.data('hover'),
        click = el.data('click'),
        wait  = false;

    // Remove old one
    el.parent().find('.zeroClipboardDiv').remove();

    ZeroClipboard.setMoviePath('/swfs/ZeroClipboard.swf');
    var clip = new ZeroClipboard.Client(),
        href = el.attr('href'),
        link = href.match('http') ? href : ('http://' + document.location.host + href);

    if (position) clip.setPosition(position);
    clip.setHandCursor(true);
    clip.glue(target, el.parent().attr('id'));
    clip.setText(link);

    // Listeners
    clip.addEventListener('mouseOver', function (client) {
      el.trigger('mouseover').addClass('hover').html(hover);
    });
    clip.addEventListener('mouseOut', function (client) {
      if (!wait) el.trigger('mouseout').removeClass('hover').html(text);
    });
    clip.addEventListener('complete', function(client, clip) {
      el.html(click);
      $('.tipsy').remove();
      wait = true;
      setTimeout(function() { el.html(text); wait = false; }, 2000);
    });
  },

  attachSpinner: function() {
    spinner
      .spin(spinOpts)
      .removeClass('hidden')
      .css({
        left: lastPosition[0] + offset,
        top:  lastPosition[1] + offset
      });

    $('body').bind('mousemove.spinner', function(e){
      $('#spinner').css({
          left: e.pageX + offset,
          top:  e.pageY + offset
        });
    });
  },

  detachSpinner: function() {
    $(document).unbind('mousemove.spinner');
    spinner.spin(false).addClass('hidden');
  }
};