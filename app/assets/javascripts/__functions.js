var DO_LOGGING = true;

String.prototype.leftPad = function (l, c) { return new Array(l - this.length + 1).join(c || ' ') + this; }

var fn = {
  log: function() {
    if (DO_LOGGING)  {
      var caller = arguments.callee.caller ? arguments.callee.caller.name.toString().leftPad(20) : ''.leftPad(20);
      console.log(caller,Array.prototype.slice.call(arguments) );
    }
  },

  pad: function(number, length) {
    var str = '' + number;
    while (str.length < length) {
        str = '0' + str;
    }
    return str;
  },

  debounce: function(func , timeout) {
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
    if (width) {
      var left = (screen.width/2)-(width/2),
          top = (screen.height/2)-(height/2),
          newwindow = window.open(url, 'name', 'menubar=no,toolbar=no,status=no,width='+width+',height='+height+',left='+left+',top='+top);
      if (window.focus) newwindow.focus();
      return newwindow;
    }
    else {
      return window.open(url);
    }
  },

  replaceState: function(url, container) {
    return $.pjax({
      url: url,
      container: '#body',
      dontDoAjax: true,
      replace: true
    });
    // return window.history.replaceState(null,document.title,url);
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

  flattenArray: function(array){
    var flat = [];
    for (var i = 0, l = array.length; i < l; i++){
        var type = Object.prototype.toString.call(array[i]).split(' ').pop().split(']').shift().toLowerCase();
        if (type) { flat = flat.concat(/^(array|collection|arguments|object)$/.test(type) ? this.flattenArray(array[i]) : array[i]); }
    }
    return flat;
  },

  capitalize: function(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
  },

  scrollToTop: function(time) {
    $('html,body').animate({scrollTop:0}, 200 || time);
  },

  scrollTo: function(object) {
    var top = object;
    if (typeof object != 'number') {
      var pad = $('.title.fixed').length ? 170 : 85;
      top = object.offset().top - pad;
    }

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
  }
};