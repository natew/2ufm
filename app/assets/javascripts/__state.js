// Variables
var w = $(window),
    body = $('body'),
    isProduction = body.is('.production'),
    isOnline = body.is('.signed_in'),
    isNewUser = body.is('.new_user'),
    isAdmin = $('body[data-role="admin"]').length > 0,
    userId = body.data('user'),
    modalShown = false,
    navOpen,
    navItems,
    navActive,
    hideWelcome = $.cookie('hideWelcome'),
    hasNavbar = true,
    shareSong,
    navHovered = [],
    navUnhoveredOnce = false,
    friendsTemplate = $('#friends-template').html(),
    navbarInterval,
    doPjax = true,
    isTuningIn = typeof(tuneInto) != 'undefined',
    doc,
    navHoverInterval,
    navHoverActive,
    pageLoadTimeout,
    playerBroadcastTemplate = $('#player-buttons .broadcast').html(),
    shareCount = 0,
    fakeUrl,
    newPage = window.location.pathname,
    disableHovers = false,
    navItems = {},
    genresOpen = $.cookie('genres-open') || false;
    theme = {
      body: $.cookie('theme-body') || 'theme-body-1',
      head: $.cookie('theme-head') || 'theme-head-1'
    },
    newline = "\n";