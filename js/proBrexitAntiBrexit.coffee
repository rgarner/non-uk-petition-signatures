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

class ProAntiBrexitView
  constructor: (@duellingPetitions, @ukOrNonUk, @tableOrBubble) ->
    console.log 'constructor', @duellingPetitions, @ukOrNonUk, @tableOrBubble

  drawTable = () ->
    tableBody = $('#bars tbody')
    tableBody.find('tr').remove()

    source = if @ukOrNonUk == 'uk' then @duellingPetitions.byConstituency \
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
        'en-GB', minimumFractionDigits: 0)} (#{stats.petitions[0].percentage.toFixed(1)}%) are pro-Remain.")
    $('.progress-bar-pro-trump').attr('style', "width: #{stats.petitions[1].percentage.toFixed(1)}%")
    $('.progress-bar-pro-trump span').text(
      "#{stats.petitions[1].total.toLocaleString(
        'en-GB', minimumFractionDigits: 0)} (#{stats.petitions[1].percentage.toFixed(1)}%) anti.")

  createTooltip = (vis, svg) ->
    tip = d3.tip(vis)
      .attr('class', 'd3-tip')
      .offset([-10, 0])
      .html((d) ->
        formattedPercentages = [
          d.percentage.toFixed(1),
          (100 - d.percentage).toFixed(1)
        ]
        """
          <h4>#{d.name}</h4>
          <p><span class='value'>#{d.size.toLocaleString('en-GB')}</span> signatures, of which</p>
          <div class="progress">
              <div class="progress-bar progress-bar-anti-trump" style="width: #{formattedPercentages[0]}%">
                  <span>#{formattedPercentages[0]}% are pro-Remain</span>
              </div>
              <div class="progress-bar progress-bar-warning progress-bar-pro-trump" role="progressbar"
                   style="width:#{formattedPercentages[1]}%"
              >
                  <span>#{formattedPercentages[1]}% anti</span>
              </div>
          </div>
        """
      )
    svg.call(tip)
    tip

  drawBubbles = () ->
    source = if @ukOrNonUk == 'uk' then @duellingPetitions.byConstituency \
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

    margin = { top: 0, right: 40, bottom: 0, left: 40 }

    diameter = window.innerWidth - margin.left - margin.right
    graph = d3.select('#graph')
    graph.select('svg').remove()
    svg = graph.append('svg')
      .attr('width', diameter)
      .attr('height', diameter)

    bubble = d3.layout.pack()
      .size([diameter, diameter])
      .sort((a, b) -> if a.size > b.size then -1 else 1)
      .value( (d) -> d.size )
      .padding(2)

    data = processData(source)
    nodes = bubble.nodes(data).filter((d) -> !d.children )

    color = d3.scale.linear().domain([0,100]).range(['#f0ad4e', '#337ab7'])

    vis = svg.selectAll('circle').data(nodes)

    tip = createTooltip(vis, svg)

    group = vis.enter()
      .append('g')
      .attr('class', 'area-group')
      .on('mouseover', tip.show)
      .on('mouseout', tip.hide)

    textVisibilityThreshold = if @ukOrNonUk == 'uk' then 15000 else 300

    group.append('circle')
      .attr("transform", (d) -> "translate(#{d.x},#{d.y})")
      .attr('r', (d) -> d.r )
      .attr('class', (d) -> d.className)
      .attr('style', (d) -> "fill: #{color(d.percentage)}")

    group.append('circle')
      .attr("transform", (d) -> "translate(#{d.x},#{d.y})")
      .attr('r', (d) -> d.r * ((100 - d.percentage) / 100))
      .attr('class', (d) -> d.className)
      .attr('disabled', 'disabled')
      .attr('style', "fill: #f0ad4e")

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
      .attr('transform', (d) -> "translate(#{d.x},#{d.y})")
      .text((d) -> d.name if d.size > textVisibilityThreshold)
      .append('svg:tspan')
      .attr('x', 0)
      .attr('dy', 20)
      .text((d) -> d.size.toLocaleString('en-GB') if d.size > textVisibilityThreshold)

    group.append('circle')
      .attr("transform", (d) -> "translate(#{d.x},#{d.y})")
      .attr('r', (d) -> d.r )
      .attr('class', 'click-capture')
      .style('visibility', 'hidden')

  draw: () =>
    setupTitle.call(this)
    setupSummaryProgressBar.call(this)
    console.log @tableOrBubble
    if @tableOrBubble == 'table'
      $('#bars').removeClass('hidden')
      $('#graph').addClass('hidden')
      drawTable.call(this)
    else
      $('#bars').addClass('hidden')
      $('#graph').removeClass('hidden')
      drawBubbles.call(this)

class @ProBrexitAntiBrexitManager
  constructor: () ->

  oppositeUkOrNonUk = (ukOrNonUk) ->
    if ukOrNonUk == 'uk' then 'non-uk' else 'uk'

  oppositeTableOrBubble = (tableOrBubble) ->
    if tableOrBubble == 'table' then 'bubble' else 'table'

  setupUkNonUkLinks: =>
    $('.menu-non-uk a').attr('href', "#/non-uk/#{@tableOrBubble}")
    $('.menu-uk a').attr('href', "#/uk/#{@tableOrBubble}")

  setupTableBubbleLinks: =>
    $('.menu-table a').attr('href', "#/#{@ukOrNonUk}/table")
    $('.menu-bubble a').attr('href', "#/#{@ukOrNonUk}/bubble")

  makeDropdownReflectUkOrNonUk: () =>
    active = @ukOrNonUk
    activeText = $("li.menu-#{active}").addClass('disabled').text()
    $("li.menu-#{oppositeUkOrNonUk(active)}").removeClass('disabled')
    $('.uk-non-uk .inline-label').text(activeText)

  makeDropdownReflectTableOrBubble: () =>
    active = @tableOrBubble
    activeText = $("li.menu-#{active}").addClass('disabled').text()
    $("li.menu-#{oppositeTableOrBubble(active)}").removeClass('disabled')
    $('.graph-type .inline-label').text(activeText)

  setup: (ukOrNonUk = 'non-uk', tableOrBubble = 'table') ->
    @ukOrNonUk = ukOrNonUk
    @tableOrBubble = tableOrBubble

    console.log(@ukOrNonUk, @tableOrBubble)

    proRemain  = 'https://petition.parliament.uk/petitions/241584.json'
    antiRemain = 'https://petition.parliament.uk/petitions/229963.json'

    duellingPetitions = new DuellingPetitions(proRemain, antiRemain)
    duellingPetitions.getBoth(->
      view = new ProAntiBrexitView(duellingPetitions, ukOrNonUk, tableOrBubble)
      view.draw()
    )
    @setupUkNonUkLinks()
    @setupTableBubbleLinks()
    @makeDropdownReflectUkOrNonUk()
    @makeDropdownReflectTableOrBubble()




