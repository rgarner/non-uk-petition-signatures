// Generated by CoffeeScript 1.9.3
(function() {
  jQuery(function() {
    var root, useHash;
    root = null;
    useHash = true;
    window._router = new Navigo(root, useHash);
    window._pageManager = new ProTrumpAntiTrumpManager();
    return window._router.on({
      '/uk': function() {
        return _pageManager.setup('uk');
      },
      '/': function() {
        return _pageManager.setup('non-uk');
      }
    }).resolve();
  });

}).call(this);

//# sourceMappingURL=_initProTrumpAntiTrump.js.map
