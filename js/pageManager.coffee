class @PageManager
  @createOrReplaceChart = (petitionData, toShow) ->
    if window._chart
      window._chart.replace()
    window._chart = new Chart(petitionData, { filter: 'GB', toShow: toShow })
    window._chart.draw()

  @setup: (petitionUrl) ->
    $.ajax
      url: petitionUrl
      dataType: "json"
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("Couldn't get petition JSON - #{textStatus}: #{errorThrown}")
      success: (petitionJson) ->
        petitionData = new PetitionData(petitionJson)
        # Common elements
        PageManager.setupTitle(petitionData)
        PageManager.setupSubtitle(petitionData)
        PageManager.setupProgressBar(petitionData)
        PageManager.setupToShowButtons()
        PageManager.setupUkNonUkButtons()

        # Country-specific elements
        PageManager.setupNonUkSummary(petitionData)
        PageManager.setupCsvDownload(petitionData)
        PageManager.createOrReplaceChart(petitionData, PageManager.currentToShowValue())

        # TODO: Constituency-specific elements

  @setupSubtitle: (petitionData) ->
    $('.subtitle .n')
      .text(petitionData.stats().total.toLocaleString('en-GB', {minimumFractionDigits: 0}))

  @setupProgressBar: (petitionData) ->
    stats = petitionData.stats()
    wereAre = if petitionData.state() == 'open' then 'are' else 'were'

    $('.progress-bar.uk').attr('style', "width: #{stats.percentage_uk.toFixed(1)}%")
    $('.progress-bar.uk span').text(
      "#{stats.uk_total.toLocaleString(
        'en-GB', {minimumFractionDigits: 0})} (#{stats.percentage_uk.toFixed(1)}%) #{wereAre} from the UK.")
    $('.progress-bar.non-uk').attr('style', "width: #{stats.percentage_international.toFixed(1)}%")
    $('.progress-bar.non-uk span').text("#{stats.percentage_international.toFixed(1)}% non-UK")
    $('.were-are').text(wereAre)

  @setupNonUkSummary: (petitionData) ->
    stats = petitionData.stats()
    $('.non-uk-summary .country-count').text(stats.non_uk_country_count)
    $('.non-uk-summary .slice-n').text(PageManager.currentToShowValue())
    $('.non-uk-summary .n').text("#{stats.international_total.toLocaleString('en-GB', {minimumFractionDigits: 0})}")
    $('.non-uk-summary .percent').text("#{stats.percentage_international.toFixed(1)}%")

  @currentToShowValue: () ->
    parseInt($('button.to-show.active').attr('data-to-show'))

  @setupUkNonUkButtons: () ->
    $('.uk-non-uk .dropdown-menu a').click (e) ->
      $('.uk-non-uk .dropdown-menu li').removeClass('disabled')
      selectedMenuItem = $(e.currentTarget)
      selectedMenuItem.parent('li').addClass('disabled')
      $('.uk-non-uk .inline-label').text(selectedMenuItem.text())
      PageManager.switchTo(selectedMenuItem.text())

  @setupToShowButtons: () ->
    $('button.to-show').click (e) ->
      $('button.to-show').removeClass('active')
      toShow = parseInt($(e.currentTarget).addClass('active').attr('data-to-show'))
      PageManager.createOrReplaceChart(window._chart.petitionData, toShow)
      PageManager.setupNonUkSummary(window._chart.petitionData)

  @setupTitle: (petitionData) ->
    $('.petition-title').text('')
    $('.petition-title a').remove()
    $('.petition-title').append('<a />')
    $('.petition-title a')
      .text("#{petitionData.title()} ")
      .attr('href', petitionData.url())

    $('.petition-title').append(
      "<span class='badge #{petitionData.state()}'>#{petitionData.state().capitalizeFirstLetter()}</span>"
    )

  @download: (petitionData) ->
    signaturesByCountry = petitionData.signaturesByCountryDescendingCount({filter: 'NONE'})

    csv = "data:text/csv;charset=utf-8,country_code, country_name, signature_count\n"
    for country, index in signaturesByCountry
      row = [country.code, "\"#{country.name}\"", country.signature_count].join(",")
      csv += row
      csv += "\n" if index < signaturesByCountry.length

    encodedUri = encodeURI(csv)
    window.open(encodedUri)

  @setupCsvDownload: (petitionData) ->
    $('#download').unbind('click').click ->
      PageManager.download(petitionData)

  @switchTo: (ukNonUk) ->
    console.log("switching to #{ukNonUk}")
