class @PetitionData
  TOP = 50

  constructor: (@petitionJson) ->

  title: () =>
    @petitionJson.data.attributes.action

  signaturesByCountry: () =>
    @_signaturesByCountry = @petitionJson.data.attributes.signatures_by_country.filter (country) ->
      country.code != 'GB'

  signatureCountForName: (name) ->
    @signaturesByCountry().find((c) -> c.name == name).signature_count

  uk: () =>
    countries = @petitionJson.data.attributes.signatures_by_country
    (c for c in countries when c.code is 'GB')[0]

  signaturesByCountryDescendingCount: () =>
    descending = @signaturesByCountry().sort (prev, current) ->
      if current.signature_count > prev.signature_count then 1 else -1
    descending[0..TOP - 1]

  maxCountryFrequency: () =>
    @signaturesByCountryDescendingCount()[0].signature_count
