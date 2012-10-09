$.fn.allOn = function(onEvent, bindings) {
  for (var target in bindings) {
    $(this).on(onEvent, target, function(e) {
      bindings[target].call(e, $(this));
    });
  }
}