$.fn.allOn = function(onEvent, bindings) {
  fn.log(bindings);
  for (var target in bindings) {
    fn.log(target, onEvent, this);
    $(this).on(onEvent, target, function(e) {
      var t = target;
      fn.log('calling', t);
      bindings[t].call(e, $(this));
    });
  }
}