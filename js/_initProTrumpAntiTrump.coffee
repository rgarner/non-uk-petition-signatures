jQuery ->
  root = null
  useHash = true
  window._router = new Navigo(root, useHash);

  window._proTrumpAntiTrumpManager = new ProTrumpAntiTrumpManager()
  window._proTrumpAntiTrumpManager.setup('non-uk')
