$.fn.dontScrollParent = function()
{
    var el = $(this),
        atTop = true,
        atBottom = false;

    if (el.is('scroll-bound')) return false;
    el.addClass('atTop scroll-bound');

    this.unbind('mousewheel DOMMouseScroll');

    this.bind('mousewheel DOMMouseScroll',function(e)
    {
        var delta = e.originalEvent.wheelDelta || -e.originalEvent.detail;

        if (delta > 0 && el.scrollTop() <= 0) {
            el.addClass('atTop');
            atTop = true;
            return false;
        } else {
            if (atTop) {
                el.removeClass('atTop');
                atTop = false;
            }
        }

        if (delta < 0 && el.scrollTop() >= this.scrollHeight - el.outerHeight()) {
            el.addClass('atBottom');
            atBottom = true;
            return false;
        } else {
            if (atBottom) {
                el.removeClass('atBottom');
                atBottom = false;
            }
        }

        return true;
    });

    return el;
}