class @PageManager
  constructor: (@router) ->
    @arrivedDirectlyAtAPetition = false

  createOrReplaceChart: () =>
    if window._chart
      window._chart.replace()

    if @ukNonUk() == 'uk'
      slicedData = @petitionData.signaturesByConstituencyDescendingCount({ top: currentToShowValue() })
    else
      slicedData = @petitionData.signaturesByCountryDescendingCount({ filter: 'GB', top: currentToShowValue() })

    xAxisLabels = slicedData.map (area) -> area.name
    data = slicedData.map (area) -> area.signature_count

    window._chart = new Chart(data, xAxisLabels, { toShow: currentToShowValue() })
    window._chart.draw()

  navigateToPetition: (petitionIdOrUrl, ukOrNonUk = 'non-uk') =>
    @petitionUrl = new PetitionUrl(petitionIdOrUrl)

    console.log("going to #{@petitionUrl.toString()}")

    $.ajax
      url: @petitionUrl.toString()
      dataType: "json"
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("Couldn't get petition JSON - #{textStatus}: #{errorThrown}")
      success: (petitionJson) =>
        @petitionData = new PetitionData(petitionJson)

        # Common elements
        @setupTitle()
        @setupSubtitle()
        @setupProgressBar()
        @setupToShowButtons()
        @setupUkNonUkLinks()
        @setUkOrNonUk(ukOrNonUk)
        @toggleSubtitleVisibility()
        @togglePetitionsMenuUk()

        # Country-specific elements
        @setupNonUkSummary()
        @setupCsvDownload()

        # Constituency-specific elements
        @setupUkSummary()

        # Chart
        @createOrReplaceChart(currentToShowValue())

    @arrivedDirectlyAtAPetition = true

  setupSubtitle: =>
    $('.subtitle .n')
      .text(@petitionData.stats().total.toLocaleString('en-GB', {minimumFractionDigits: 0}))

  setupProgressBar: =>
    stats = @petitionData.stats()
    wereAre = if @petitionData.state() == 'open' then 'are' else 'were'

    $('.progress-bar-uk').attr('style', "width: #{stats.percentage_uk.toFixed(1)}%")
    $('.progress-bar-uk span').text(
      "#{stats.uk_total.toLocaleString(
        'en-GB', {minimumFractionDigits: 0})} (#{stats.percentage_uk.toFixed(1)}%) #{wereAre} from the UK.")
    $('.were-are').text(wereAre)

  setupNonUkSummary: =>
    stats = @petitionData.stats()
    $('.non-uk-summary .country-count').text(stats.non_uk_country_count)
    $('.non-uk-summary .slice-n').text(currentToShowValue())
    $('.non-uk-summary .n').text("#{stats.international_total.toLocaleString('en-GB', {minimumFractionDigits: 0})}")
    $('.non-uk-summary .percent').text("#{stats.percentage_international.toFixed(1)}%")

  setupUkSummary: =>
    stats = @petitionData.stats()
    $('.uk .constituency-count').text(stats.uk_constituency_count)

  currentToShowValue = ->
    parseInt($('button.to-show.active').attr('data-to-show'))

  setupUkNonUkLinks: =>
    $('.menu-non-uk a').attr('href', @petitionUrl.ourUrl())
    $('.menu-uk a').attr('href', "#{@petitionUrl.ourUrl()}/uk")

  setupToShowButtons: =>
    $('button.to-show').click (e) =>
      $('button.to-show').removeClass('active')
      toShow = parseInt($(e.currentTarget).addClass('active').attr('data-to-show'))
      @createOrReplaceChart(toShow)
      @setupNonUkSummary()

  setupTitle: =>
    $('.petition-title').text('')
    $('.petition-title a').remove()
    $('.petition-title').append('<a />')
    $('.petition-title a')
      .text("#{@petitionData.title()} ")
      .attr('href', @petitionData.url())

    $('.petition-title').append(
      "<span class='badge #{@petitionData.state()}'>#{@petitionData.state().capitalizeFirstLetter()}</span>"
    )

  downloadCountryCsv: =>
    signaturesByCountry = @petitionData.signaturesByCountryDescendingCount({filter: 'NONE'})

    csv = "data:text/csv;charset=utf-8,country_code, country_name, signature_count\n"
    for country, index in signaturesByCountry
      row = [country.code, "\"#{country.name}\"", country.signature_count].join(",")
      csv += row
      csv += "\n" if index < signaturesByCountry.length

    encodedUri = encodeURI(csv)
    window.open(encodedUri)

  downloadConstituencyCsv: =>
    signaturesByConstituency = @petitionData.signaturesByConstituencyDescendingCount()

    csv = "data:text/csv;charset=utf-8,name,ons_code,mp,signature_count\n"
    for constituency, index in signaturesByConstituency
      row = ["\"#{constituency.name}\"", constituency.ons_code, constituency.mp, constituency.signature_count].join(",")
      csv += row
      csv += "\n" if index < signaturesByConstituency.length

    encodedUri = encodeURI(csv)
    window.open(encodedUri)

  setupCsvDownload: () =>
    $('#download').unbind('click').click =>
      if @ukNonUk() == 'uk'
        @downloadConstituencyCsv()
      else
        @downloadCountryCsv()

  toggleSubtitleVisibility: () ->
    nowCurrent = @ukNonUk()

    showingClass = ".#{nowCurrent}"
    hidingClass = if nowCurrent == 'uk' then '.non-uk' else '.uk'
    $(showingClass).removeClass('hidden')
    $(hidingClass).addClass('hidden')

  togglePetitionsMenuUk: () =>
    petitionsLinks = $('.petitions.dropdown-menu li a')
    if @ukNonUk() == 'uk'
      petitionsLinks.attr('href', ->
        $(this).attr('href') + '/uk' unless $(this).attr('href').endsWith('/uk')
      )
    else
      petitionsLinks.attr('href', -> $(this).attr('href').replace('/uk',''))

  oppositeUkOrNonUk = (ukOrNonUk) ->
    if ukOrNonUk == 'uk' then 'non-uk' else 'uk'

  ukNonUk: ->
    # The one that's disabled is the one already selected
    $('.uk-non-uk li.disabled a').text().toLowerCase()

  setUkOrNonUk: (active) ->
    activeText = $("li.menu-#{active}").addClass('disabled').text()
    $("li.menu-#{oppositeUkOrNonUk(active)}").removeClass('disabled')
    $('.uk-non-uk .inline-label').text(activeText)
