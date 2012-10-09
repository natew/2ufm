$.fn.allOn = function(onEvent, bindings) {
  console.log(bindings);
  for (var target in bindings) {
    console.log(target, onEvent);
    $(this).on(onEvent, target, function(e) {
      bindings[target].call(e, $(this));
    });
  }
}