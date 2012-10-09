// Variables
var w = $(window),
    body = $('body'),
    isOnline = $('body.signed_in').length > 0,
    isAdmin = $('body[data-role="admin"]').length > 0,
    userId = body.data('user'),
    modalShown = false,
    navOpen,
    navItems,
    navActive,
    hideWelcome = $.cookie('hideWelcome'),
    volume = mp.volume(),
    playMode = mp.playMode(),
    hasNavbar = true,
    shareSong,
    navHovered = [],
    navUnhoveredOnce = false,
    friendsTemplate = $('#friends-template').html(),
    navbarInterval,
    playModeEl = $('#player-mode'),
    modeTitles = {'normal': 'Normal', 'repeat': 'Repeat', 'shuffle': 'Shuffle'},
    playAfterLoad,
    doPjax = true,
    isTuningIn = typeof(tuneInto) != 'undefined',
    doc;