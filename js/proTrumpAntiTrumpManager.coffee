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

  byConstituency: () =>
    percentage = (c1, c2) ->
      total = c1.signature_count + c2.signature_count
      (c1.signature_count / total) * 100

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

class ProAntiTrumpView
  constructor: (@duellingPetitions) ->

  drawTable = (tableBody) ->
    tableBody.find('tr').remove()
    sortedByDescendingPetition1Percentage = @duellingPetitions.byConstituency().sort(
      (c1, c2) ->
        if c1.petitions[0].percentage < c2.petitions[0].percentage then 1 else -1
    )

    for constituency in sortedByDescendingPetition1Percentage
      tableBody.append(
        """
          <tr>
            <td class='title'>#{constituency.name}</td>
            <td class='bar'>
              <div class="progress-bar" style='width: #{constituency.petitions[0].percentage}%'>
                  <span>#{constituency.petitions[0].percentage.toFixed(1)}%</span>
              </div>
              <div class="progress-bar progress-bar-warning" role="progressbar" style='width: #{constituency.petitions[1].percentage}%'>
                  <span>#{constituency.petitions[1].percentage.toFixed(1)}%</span>
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


  draw: (tableBody) =>
    setupTitle.call(this)
    setupSummaryProgressBar.call(this)
    drawTable.call(this, tableBody)

class @ProTrumpAntiTrumpManager
  constructor: () ->

  setup: (ukOrNonUk) ->
    antiTrump = 'https://petition.parliament.uk/petitions/171928.json'
    proTrump = 'https://petition.parliament.uk/petitions/178844.json'
    duellingPetitions = new DuellingPetitions(antiTrump, proTrump)
    duellingPetitions.getBoth(->
      view = new ProAntiTrumpView(duellingPetitions)
      view.draw($('#bars tbody'))
    )




