jQuery ->
  root = null
  useHash = true
  window._router = new Navigo(root, useHash);

  window._pageManager = new PageManager(window._router)

  window._router.on(
    '/petitions/:id/uk': (params) ->
      _pageManager.navigateToPetition(params.id, 'uk')
    ,
    '/petitions/:id': (params) ->
      _pageManager.navigateToPetition(params.id)
  ).resolve()

  DEFAULT_TO_TRUMP_OR_NO_FUNDING = "/petitions/171928"

  unless window._pageManager.arrivedDirectlyAtAPetition
    window._router.navigate(DEFAULT_TO_TRUMP_OR_NO_FUNDING)

