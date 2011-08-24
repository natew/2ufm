function fitStringToWidth(str,width,className) {
  // str    A string where html-entities are allowed but no tags.
  // width  The maximum allowed width in pixels
  // className  A CSS class name with the desired font-name and font-size. (optional)
  // ----
  // _escTag is a helper to escape 'less than' and 'greater than'
  function _escTag(s){ return s.replace("<","&lt;").replace(">","&gt;");}

  //Create a span element that will be used to get the width
  var span = document.createElement("span");
  //Allow a classname to be set to get the right font-size.
  if (className) span.className=className;
  span.style.display='inline';
  span.style.visibility = 'hidden';
  span.style.padding = '0px';
  document.body.appendChild(span);

  var result = _escTag(str); // default to the whole string
  span.innerHTML = result;
  // Check if the string will fit in the allowed width. NOTE: if the width
  // can't be determinated (offsetWidth==0) the whole string will be returned.
  if (span.offsetWidth > width) {
    var posStart = 0, posMid, posEnd = str.length, posLength;
    // Calculate (posEnd - posStart) integer division by 2 and
    // assign it to posLength. Repeat until posLength is zero.
    while (posLength = (posEnd - posStart) >> 1) {
      posMid = posStart + posLength;
      //Get the string from the begining up to posMid;
      span.innerHTML = _escTag(str.substring(0,posMid)) + '&hellip;';

      // Check if the current width is too wide (set new end)
      // or too narrow (set new start)
      if ( span.offsetWidth > width ) posEnd = posMid; else posStart=posMid;
    }

    result = '<abbr title="' +
      str.replace("\"","&quot;") + '">' +
      _escTag(str.substring(0,posStart)) +
      '&hellip;<\/abbr>';
  }
  document.body.removeChild(span);
  return result;
}