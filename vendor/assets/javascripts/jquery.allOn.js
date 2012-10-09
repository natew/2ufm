$.fn.allOn = function(onEvent, bindings) {
  for (var target in bindings) {
    (function(t) {
      $(this).on(onEvent, t, function(e) {
        bindings[t].call(this, e, $(this));
      });
    })(target);
  }
}