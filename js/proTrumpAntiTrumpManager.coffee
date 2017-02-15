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

    sortedByTotalSignatures = source().sort(
      (c1, c2) ->
        signature_counts = [c1, c2].map (area) -> area.petitions[0].signature_count + area.petitions[1].signature_count
        if signature_counts[0] < signature_counts[1] then 1 else -1
    )

    for area in sortedByTotalSignatures
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

    $('.progress-bar-anti-trump').attr('style', "width: #{stats.petitions[0].percentage.toFixed(1)}%")
    $('.progress-bar-anti-trump span').text(
      "#{stats.petitions[0].total.toLocaleString(
        'en-GB', minimumFractionDigits: 0)} (#{stats.petitions[0].percentage.toFixed(1)}%) are anti-Trump.")
    $('.progress-bar-pro-trump').attr('style', "width: #{stats.petitions[1].percentage.toFixed(1)}%")
    $('.progress-bar-pro-trump span').text(
      "#{stats.petitions[1].total.toLocaleString(
        'en-GB', minimumFractionDigits: 0)} (#{stats.petitions[1].percentage.toFixed(1)}%) pro.")

  drawBubbles = (ukOrNonUk) ->
    source = if ukOrNonUk == 'uk' then @duellingPetitions.byConstituency \
                                  else @duellingPetitions.byCountry

    processData = (source) ->
      sigMax = 0
      sigMin = 9999999999

      children = source().map (area) ->
        totalSignatures = area.petitions[0].signature_count + area.petitions[1].signature_count
        sigMin = totalSignatures if totalSignatures < sigMin
        sigMax = totalSignatures if totalSignatures > sigMax

        {
          name: area.name
          className: area.ons_code || area.code
          code: area.code
          percentage: area.petitions[0].percentage
          size: area.petitions[0].signature_count + area.petitions[1].signature_count
        }

      {
        sigMin: sigMin
        sigMax: sigMax
        children: children
      }

    margin = { top: 40, right: 20, bottom: 40, left: 20 }

    diameter = window.innerWidth - margin.left - margin.right
    graph = d3.select('#graph')
    graph.select('svg').remove()
    svg = graph.append('svg')
      .attr('width', diameter)
      .attr('height', diameter)

    bubble = d3.layout.pack()
      .size([diameter, diameter])
      .sort((a, b) -> -(a.size > b.size))
      .value( (d) -> d.size )
      .padding(2)

    data = processData(source)
    nodes = bubble.nodes(data).filter((d) -> !d.children )

    color = d3.scale.linear().domain([0,100]).range(['#f0ad4e', '#337ab7'])
    size  = d3.scale.linear().domain([data.sigMin,data.sigMax]).range([0, 20])

    vis = svg.selectAll('circle').data(nodes)

    group = vis.enter().append('g')

    textVisibilityThreshold = if ukOrNonUk == 'uk' then 7000 else 300

    mainCircle = group.append('circle')
      .attr("transform", (d) -> "translate(#{d.x},#{d.y})")
      .attr('r', (d) -> d.r )
      .attr('class', (d) -> d.className)
      .attr('style', (d) -> "fill: #{color(d.percentage)}")

    tooltipTitle = (d) ->
      "#{d.name} (#{(100 - d.percentage).toFixed(1)}% of #{d.size} signatures were pro-Trump)"

    mainCircle.append('title').text(tooltipTitle)

    group.append('circle')
      .attr("transform", (d) -> "translate(#{d.x},#{d.y})")
      .attr('r', (d) -> d.r * ((100 - d.percentage) / 100))
      .attr('class', (d) -> d.className)
      .attr('style', "fill: #f0ad4e")
      .append('title').text(tooltipTitle)

    convertProTrumpPercentageToRadians = (d) ->
      (100 - d.percentage) / 100 * 360 * Math.PI / 180

    arc = d3.svg.arc()
      .innerRadius((d) -> d.r * 0.85)
      .outerRadius((d) -> d.r)
      .startAngle(convertProTrumpPercentageToRadians)
      .endAngle(0 * (Math.PI/180))

    vis.append("path")
      .attr("class", "pro")
      .attr("d", arc)
      .attr("transform", (d) -> "translate(#{d.x},#{d.y})")

    group.append('text')
      .attr('transform', (d) -> "translate(#{ d.x  },#{d.y - size(d.size)})")
      .text((d) -> d.name if d.size > textVisibilityThreshold)
      .append('svg:tspan')
      .attr('x', 0)
      .attr('dy', 20)
      .text((d) -> d.size if d.size > textVisibilityThreshold)

  draw: (tableBody, ukOrNonUk) =>
    setupTitle.call(this)
    setupSummaryProgressBar.call(this)
#    drawTable.call(this, tableBody, ukOrNonUk)
    drawBubbles.call(this, ukOrNonUk)

class @ProTrumpAntiTrumpManager
  constructor: () ->

  oppositeUkOrNonUk = (ukOrNonUk) ->
    if ukOrNonUk == 'uk' then 'non-uk' else 'uk'

  ukNonUk: ->
    # The one that's disabled is the one already selected
    $('.uk-non-uk li.disabled a').text().toLowerCase()

  setupUkNonUkLinks: =>
    $('.menu-non-uk a').attr('href', '#/')
    $('.menu-uk a').attr('href', "#/uk")

  makeDropdownReflectUkOrNonUk: (active) =>
    activeText = $("li.menu-#{active}").addClass('disabled').text()
    $("li.menu-#{oppositeUkOrNonUk(active)}").removeClass('disabled')
    $('.uk-non-uk .inline-label').text(activeText)

  setup: (ukOrNonUk) ->
    antiTrump = 'https://petition.parliament.uk/petitions/171928.json'
    proTrump = 'https://petition.parliament.uk/petitions/178844.json'
    duellingPetitions = new DuellingPetitions(antiTrump, proTrump)
    duellingPetitions.getBoth(->
      view = new ProAntiTrumpView(duellingPetitions)
      view.draw($('#bars tbody'), ukOrNonUk)
    )
    @setupUkNonUkLinks()
    @makeDropdownReflectUkOrNonUk(ukOrNonUk)




