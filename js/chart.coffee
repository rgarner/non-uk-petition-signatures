String::capitalizeFirstLetter = ->
    @charAt(0).toUpperCase() + @slice(1)

class @Chart
  margin = { top: 40, right: 70, bottom: 150, left: 70 }

  constructor: (@petitionData, @options = { toShow: 25 }) ->
    slicedData = @petitionData.signaturesByCountryDescendingCount({filter: 'GB', top: @options.toShow})
    @xAxisLabels = slicedData.map (country) -> country.name
    @data = slicedData.map (country) -> country.signature_count

    d3.select(window).on('resize', @resize)

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

    @x ||= d3.scale.ordinal().domain(@xAxisLabels)
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
