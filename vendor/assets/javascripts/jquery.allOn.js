$.fn.allOn = function(onEvent, bindings) {
  var parent = this;

  for (var target in bindings) {
    bindClick(target);
  }

  function bindClick(target) {
    $(parent).on(onEvent, target, function(e) {
      bindings[target].call(this, e, $(this));
    });
  }
}