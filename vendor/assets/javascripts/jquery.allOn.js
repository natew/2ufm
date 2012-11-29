$.fn.allOn = function(onEvent, bindings) {
  for (var target in bindings) {
    bindClick(target);
  }

  function bindClick(t) {
    fn.log('bingin', t)
    $(this).on(onEvent, t, function(e) {
      bindings[t].call(this, e, $(this));
    });
  }
}