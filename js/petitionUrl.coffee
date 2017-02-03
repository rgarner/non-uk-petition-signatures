class @PetitionUrl
  PETITION_URL_REGEX = /https:\/\/petition\.parliament\.uk\/petitions\/([0-9]+)(?:.json)?/

  constructor: (idOrUrl) ->
    if match = idOrUrl.match PETITION_URL_REGEX
      @petitionId = match[1]
      @petitionUrl = idOrUrl
    else if idOrUrl.match /[0-9]/
      @petitionUrl = "https://petition.parliament.uk/petitions/#{idOrUrl}.json"
      @petitionId = idOrUrl
    else
      throw "#{idOrUrl} is neither an ID nor a URL"

  ourUrl: =>
    "#/petitions/#{@petitionId}"

  toString: =>
    @petitionUrl

