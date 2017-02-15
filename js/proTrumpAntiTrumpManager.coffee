class DuellingPetitions
  constructor: (@url1, @url2) ->

  get = (url) ->
    $.ajax
      url: url.toString()
      dataType: "json"
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("Couldn't get petition JSON - #{textStatus}: #{errorThrown}")
      success: (petitionJson) =>
        console.log("got #{url} JSON:", petitionJson)

  getBoth: (callback) =>
    $.when(get(@url1), get(@url2)).done((a1, a2) =>
      @petition1 = new PetitionData(a1[0])
      @petition2 = new PetitionData(a2[0])

      callback()
    )

  totalSignatures: () =>
    @petition1.stats().total + @petition2.stats().total

  stats: () =>
    stats = [@petition1.stats(), @petition2.stats()]

    total = stats[0].total + stats[1].total
    total: total
    petitions: [
      {
        title: @petition1.title(),
        total: stats[0].total
        percentage: (stats[0].total / total) * 100
      },
      {
        title: @petition2.title(),
        total: stats[1].total
        percentage: (stats[1].total / total) * 100
      }
    ]

  percentage = (c1, c2) ->
    total = c1.signature_count + c2.signature_count
    (c1.signature_count / total) * 100

  byConstituency: () =>
    @petition1.signaturesByConstituency().map( (constituency) =>
      constituency2 =
        @petition2.signaturesByConstituency().find((c)-> c.ons_code == constituency.ons_code)
      mappedConstituency =
          name: constituency.name,
          mp: constituency.mp,
          ons_code: constituency.ons_code
          petitions: [
            {
              title: @petition1.title()
              signature_count: constituency.signature_count
              percentage: percentage(constituency, constituency2)
            },
            {
              title: @petition2.title()
              signature_count: constituency2.signature_count
              percentage: percentage(constituency2, constituency)
            }
          ]

      mappedConstituency
    )

  byCountry: () =>
    @petition1.signaturesByCountry().map( (country) =>
      country2 =
        @petition2.signaturesByCountry().find((c)-> c.code == country.code) ||
          name: country.name
          code: country.code
          signature_count: 0

      mappedCountry =
        name: country.name,
        code: country.code
        petitions: [
          {
            title: @petition1.title()
            signature_count: country.signature_count
            percentage: percentage(country, country2)
          },
          {
            title: @petition2.title()
            signature_count: country2.signature_count
            percentage: percentage(country2, country)
          }
        ]

      mappedCountry
    )

class ProAntiTrumpView
  constructor: (@duellingPetitions) ->

  drawTable = (tableBody, ukOrNonUk) ->
    tableBody.find('tr').remove()

    source = if ukOrNonUk == 'uk' then @duellingPetitions.byConstituency \
                                  else @duellingPetitions.byCountry

    sortedByDescendingPetition1Percentage = source().sort(
      (c1, c2) ->
        if c1.petitions[0].percentage < c2.petitions[0].percentage then 1 else -1
    )

    for area in sortedByDescendingPetition1Percentage
      tableBody.append(
        """
          <tr>
            <td class='title'>#{area.name}</td>
            <td class='bar'>
              <div class="progress-bar" style='width: #{area.petitions[0].percentage}%'>
                  <span>#{area.petitions[0].signature_count.toLocaleString('en-GB')} – #{area.petitions[0].percentage.toFixed(1)}%</span>
              </div>
              <div class="progress-bar progress-bar-warning" role="progressbar" style='width: #{area.petitions[1].percentage}%'>
                  <span>#{area.petitions[1].percentage.toFixed(1)}%</span>
              </div>
            </td>
          </tr>
        """
      )

  setupTitle = ->
    $('.subtitle .n').text(
      @duellingPetitions.totalSignatures().toLocaleString('en-GB', minimumFractionDigits: 0)
    )

  setupSummaryProgressBar = ->
    stats = @duellingPetitions.stats()

    console.log(stats)
    $('.progress-bar-anti-trump').attr('style', "width: #{stats.petitions[0].percentage.toFixed(1)}%")
    $('.progress-bar-anti-trump span').text(
      "#{stats.petitions[0].total.toLocaleString(
        'en-GB', minimumFractionDigits: 0)} (#{stats.petitions[0].percentage.toFixed(1)}%) are anti-Trump.")
    $('.progress-bar-pro-trump').attr('style', "width: #{stats.petitions[1].percentage.toFixed(1)}%")
    $('.progress-bar-pro-trump span').text(
      "#{stats.petitions[1].total.toLocaleString(
        'en-GB', minimumFractionDigits: 0)} (#{stats.petitions[1].percentage.toFixed(1)}%) pro.")


  draw: (tableBody, ukOrNonUk) =>
    setupTitle.call(this)
    setupSummaryProgressBar.call(this)
    drawTable.call(this, tableBody, ukOrNonUk)

class @ProTrumpAntiTrumpManager
  constructor: () ->

  setupUkNonUkLinks: =>
    $('.uk-non-uk .dropdown-menu a').click (e) =>
      $('.uk-non-uk .dropdown-menu li').removeClass('disabled')
      selectedMenuItem = $(e.currentTarget)
      selectedMenuItem.parent('li').addClass('disabled')
      $('.uk-non-uk .inline-label').text(selectedMenuItem.text())
      @setup(selectedMenuItem.text().toLowerCase())

  setup: (ukOrNonUk) ->
    antiTrump = 'https://petition.parliament.uk/petitions/171928.json'
    proTrump = 'https://petition.parliament.uk/petitions/178844.json'
    duellingPetitions = new DuellingPetitions(antiTrump, proTrump)
    duellingPetitions.getBoth(->
      view = new ProAntiTrumpView(duellingPetitions)
      view.draw($('#bars tbody'), ukOrNonUk)
    )
    @setupUkNonUkLinks()




