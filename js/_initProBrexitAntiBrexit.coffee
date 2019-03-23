jQuery ->
  root = null
  useHash = true
  window._router = new Navigo(root, useHash);
  window._pageManager = new ProBrexitAntiBrexitManager()

  window._router.on(
    '/uk/bubble': () -> _pageManager.setup('uk', 'bubble')
    '/uk/table': () -> _pageManager.setup('uk', 'table')
    '/non-uk/bubble': () -> _pageManager.setup('non-uk', 'bubble')
    '/non-uk/table': () -> _pageManager.setup('non-uk', 'table')
    '/bubble': () -> window._router.navigate('/non-uk/bubble')
    '/uk': () -> window._router.navigate('/uk/table')
    '/': () -> window._router.navigate('/non-uk/table')
  ).resolve()
