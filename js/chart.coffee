class Chart
  margin = { top: 40, right: 70, bottom: 150, left: 70 }

  constructor: (@petitionData) ->
    @countryLabels = @petitionData.signaturesByCountryDescendingCount().map (country) -> country.name
    @data = @petitionData.signaturesByCountryDescendingCount().map (country) -> country.signature_count

    d3.select(window).on('resize', @resize);

  resize: () =>
    @recalculateScales()
    @drawXAxis()
    @drawYAxis()
    @svg().selectAll('rect')
      .attr('x', (d,i) => i * @barWidth)
      .attr('width', @barWidth - 1)

  recalculateScales: () =>
    @width = window.innerWidth - margin.left - margin.right
    @height = 550 - margin.top - margin.bottom

    @barWidth = @width / @data.length

    @x ||= d3.scale.ordinal().domain(@countryLabels)
    @x.rangeBands([0, @width])

    @y ||= d3.scale.linear().domain([0, @petitionData.maxCountryFrequency()])
    @y.range([@height, 0])

  xAxisGroup: () =>
    xAxisGroup = d3.select('g.x.axis')
    return xAxisGroup unless xAxisGroup.empty()

    @chartGroup().append("g")
      .attr("class", "x axis")

  yAxisGroup: () =>
    yAxisGroup = d3.select('g.y.axis')
    return yAxisGroup unless yAxisGroup.empty()

    @chartGroup().append("g")
      .attr("class", "y axis")

  drawXAxis: () =>
    @xAxisGroup()
      .attr("transform", "translate(0," + @height + ")")
      .call(@xAxis)
      .selectAll("text")
      .attr("transform", "rotate(90)")
      .attr("x", 15)
      .attr("y", 0)
      .style("text-anchor", "start");

  drawYAxis: () =>
    @yAxisGroup().call(@yAxis)

  setupSignatureCounts: () =>
    @chartGroup().selectAll(".bar")
      .data(@data)
      .enter().append("rect")
      .attr("class", "bar")
      .attr("width", @barWidth - 1)
      .attr("height", (d) => @height - @y(d))
      .attr("x", (d, i) => i * @barWidth)
      .attr("y", (d) => @y(d))
      .append("title")
      .text((d) -> "#{d} signatures")

  svg:() =>
    d3.select("#chart")
      .attr("width", @width + margin.left + margin.right)
      .attr("height", @height + margin.top + margin.bottom)

  chartGroup:() =>
    chartGroup = d3.select('.chart-group')
    return chartGroup unless chartGroup.empty()

    @svg()
      .append("g")
      .attr("class", "chart-group")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

  draw: () =>
    @recalculateScales()

    @xAxis = d3.svg.axis().scale(@x).orient("bottom")
    @yAxis = d3.svg.axis().scale(@y).orient("left")

    @drawXAxis()
    @xAxisGroup().selectAll('text')
      .append('title').text((c) =>
        signatures = @petitionData.signatureCountForName(c)
        "#{signatures} signature#{ if signatures > 1 then 's' else '' }"
      )

    @drawYAxis()
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", -63)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("Signatures")

    @setupSignatureCounts()

  replace: () =>
    $('#chartContainer #chart').remove()
    $('#chartContainer').append('<svg id="chart" />')

class @PageManager
  @setup: (petitionUrl) ->
    $.ajax
      url: petitionUrl
      dataType: "json"
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("Couldn't get petition JSON - #{textStatus}: #{errorThrown}")
      success: (petitionJson) ->
        petitionData = new PetitionData(petitionJson)
        PageManager.setupTitle(petitionData)
        PageManager.setupCsvDownload(petitionData)
        if window._chart
          window._chart.replace()
        window._chart = new Chart(petitionData)
        window._chart.draw()

  @setupTitle: (petitionData) ->
    $('.petition-title').text('')
    $('.petition-title a').remove()
    $('.petition-title').append('<a />')
    $('.petition-title a')
      .text(petitionData.title())
      .attr('href', petitionData.url())

    formattedSignatureCount = petitionData.uk().signature_count.toLocaleString('en-GB', {minimumFractionDigits: 0});
    $('.uk-signatures a').remove()
    $('.uk-signatures').text("(#{formattedSignatureCount} UK signatures)")

  @download: (petitionData) ->
    console.log(petitionData)
    ALL = 500

    signaturesByCountry = petitionData.signaturesByCountryDescendingCount(ALL)

    csv = "data:text/csv;charset=utf-8,country_code, country_name, signature_count\n"
    for country, index in signaturesByCountry
      row = [country.code, country.name, country.signature_count].join(",")
      csv += row
      csv += "\n" if index < signaturesByCountry.length

    encodedUri = encodeURI(csv)
    window.open(encodedUri);

  @setupCsvDownload: (petitionData) ->
    $('#download').click ->
      PageManager.download(petitionData)

jQuery ->
  if document.getElementById('chart')
    PageManager.setup("https://petition.parliament.uk/petitions/171928.json")
