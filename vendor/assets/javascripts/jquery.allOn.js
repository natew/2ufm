$.fn.allOn = function(onEvent, bindings) {
  fn.log(bindings);
  for (var target in bindings) {
    (function(t) {
      $(this).on(onEvent, t, function(e) {
        fn.log('calling', t);
        bindings[t].call(e, $(this));
      });
    })(target);
  }
}