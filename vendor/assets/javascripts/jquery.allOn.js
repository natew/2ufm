$.fn.allOn = function(onEvent, bindings) {
  fn.log(bindings);
  for (var target in bindings) {
    fn.log(target, onEvent);
    $(this).on(onEvent, target, function(e) {
      bindings[target].call(e, $(this));
    });
  }
}