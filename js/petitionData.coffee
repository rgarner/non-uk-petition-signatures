class @PetitionData
  TOP = 25
  ALL = 1000
  FILTER = 'GB'

  constructor: (@petitionJson) ->

  title: () =>
    @petitionJson.data.attributes.action

  url: () =>
    @petitionJson.links.self.replace('.json', '')

  state: () =>
    @petitionJson.data.attributes.state

  signaturesByCountry: (options = filter: FILTER) =>
    @_signaturesByCountry ||= @petitionJson.data.attributes.signatures_by_country.filter (country) ->
      country.code != options.filter

  signaturesByConstituency: () =>
    @petitionJson.data.attributes.signatures_by_constituency

  signaturesByConstituencyDescendingCount: (options = { top: ALL } ) =>
    descending = @signaturesByConstituency().sort (prev, current) ->
      if current.signature_count > prev.signature_count then 1 else -1
    descending[0..options.top - 1]

  uk: () =>
    countries = @petitionJson.data.attributes.signatures_by_country
    (c for c in countries when c.code is 'GB')[0]

  stats: () =>
    total = @petitionJson.data.attributes.signature_count
    non_uk_country_count = @signaturesByCountry().length
    uk_constituency_count = @petitionJson.data.attributes.signatures_by_constituency.length
    uk_total = @uk().signature_count
    accumulator = (total, c) -> total += c.signature_count
    international_total = @signaturesByCountry().reduce(accumulator, 0)
    {
      total: total
      non_uk_country_count: non_uk_country_count
      uk_constituency_count: uk_constituency_count
      uk_total: uk_total
      international_total: international_total
      percentage_uk: (uk_total / total) * 100
      percentage_international: (international_total / total) * 100
    }

  signaturesByCountryDescendingCount: (options = { top: TOP, filter: FILTER }) =>
    descending = @signaturesByCountry({filter: options.filter}).sort (prev, current) ->
      if current.signature_count > prev.signature_count then 1 else -1
    descending[0..options.top - 1]

  maxCountryFrequency: () =>
    @signaturesByCountryDescendingCount()[0].signature_count
