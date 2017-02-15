jQuery ->
  root = null
  useHash = true
  window._router = new Navigo(root, useHash);
  window._pageManager = new ProTrumpAntiTrumpManager()

  window._router.on(
    '/uk': () -> _pageManager.setup('uk')
    ,
    '/': () -> _pageManager.setup('non-uk')
  ).resolve()
