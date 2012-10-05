$.fn.dontScrollParent = function()
{
    this.bind('mousewheel DOMMouseScroll',function(e)
    {
        var delta = e.originalEvent.wheelDelta || -e.originalEvent.detail;

        if (delta > 0 && $(this).scrollTop() <= 0)
            return false;
        if (delta < 0 && $(this).scrollTop() >= this.scrollHeight - $(this).height())
            return false;

        return true;
    });
}