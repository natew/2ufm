$.fn.allOn = function(onEvent, bindings) {
  fn.log(bindings);
  for (var target in bindings) {
    fn.log(target, onEvent, this);
    $(this).on(onEvent, target, function(e) {
      fn.log('calling', target);
      bindings[target].call(e, $(this));
    });
  }
}