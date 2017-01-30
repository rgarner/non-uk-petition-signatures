class @PetitionData
  TOP = 10

  constructor: (@petitionJson) ->

  signaturesByCountry: () =>
    @_signaturesByCountry = @petitionJson.data.attributes.signatures_by_country.filter (country) ->
      country.code != 'GB'

  signaturesByCountryDescendingCount: () =>
    descending = @signaturesByCountry().sort (prev, current) ->
      if current.signature_count > prev.signature_count then 1 else -1
    descending[0..TOP - 1]

  maxCountryFrequency: () =>
    @signaturesByCountryDescendingCount()[0].signature_count
