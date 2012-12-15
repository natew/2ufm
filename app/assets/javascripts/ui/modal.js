
// Modal
function modal(selector, force) {
  var modal = $('#modal'),
      show = $('#overlay,#modal');

  if (modalShown || selector === false) {
    if (!modal.children('.permanent').length || force) {
      show.attr('class', '');
      body.removeClass('modal-shown');
      modalShown = false;
    }
  }
  else {
    modal.html($(selector).clone());
    show.addClass('shown').addClass(selector.substring(1));
    body.addClass('modal-shown');
    modalShown = true;
    $('input:first', modal).focus();

    // Adjust modal overflow after it animates
    setTimeout(function() {
      windowResize();
    }, 500)
  }
}
