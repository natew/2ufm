$.fn.allOn = function(onEvent, bindings) {
  for (var target in bindings) {
    (function(t) {
      $(this).on(onEvent, t, function(e) {
        $.proxy(bindings[t].call(e, $(this)), this);
      });
    })(target);
  }
}