class Chart
  margin = { top: 40, right: 70, bottom: 150, left: 70 }

  constructor: (@petitionData) ->
    @countryLabels = @petitionData.signaturesByCountryDescendingCount().map (country) -> country.name
    @data = @petitionData.signaturesByCountryDescendingCount().map (country) -> country.signature_count

    d3.select(window).on('resize', @resize);

  resize: () =>
    console.log('gi')
    @recalculateScales()
    @draw()

  recalculateScales: () =>
    @width = window.innerWidth - margin.left - margin.right
    @height = 550 - margin.top - margin.bottom

    @barWidth = @width / @data.length

    @x = d3.scale.ordinal()
      .domain(@countryLabels)
      .rangeBands([0, @width])

    @y = d3.scale.linear()
      .domain([0, @petitionData.maxCountryFrequency()])
      .range([@height, 0])

    @xAxis = d3.svg.axis().scale(@x).orient("bottom")
    @yAxis = d3.svg.axis().scale(@y).orient("left")

  drawXAxis: (svg) =>
    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + @height + ")")
      .call(@xAxis)
      .selectAll("text")
      .attr("transform", "rotate(90)")
      .attr("x", 15)
      .attr("y", 0)
      .style("text-anchor", "start");

  drawYAxis: (svg) =>
    svg.append("g")
      .attr("class", "y axis")
      .call(@yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", -63)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("Signatures")

  setupSignatureCounts: (svg) =>
    svg.selectAll(".bar")
      .data(@data)
      .enter().append("rect")
      .attr("class", "bar")
      .attr("width", @barWidth - 1)
      .attr("height", (d) => @height - @y(d))
      .attr("x", (d, i) => i * @barWidth)
      .attr("y", (d) => @y(d))

  draw: () =>
    @recalculateScales()

    svg = d3.select("#chart")
      .attr("width", @width + margin.left + margin.right)
      .attr("height", @height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

    @drawXAxis(svg)
    @drawYAxis(svg)

    @setupSignatureCounts(svg)

setupTitle = (petitionData) ->
  $('.petition-title').text(petitionData.title())
  formattedSignatureCount = petitionData.uk().signature_count.toLocaleString('en-GB', {minimumFractionDigits: 0});
  $('.uk-signatures').text("(#{formattedSignatureCount} UK signatures)")

jQuery ->
  if document.getElementById('chart')
    $.ajax
      url: "https://petition.parliament.uk/petitions/171928.json"
      dataType: "json"
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("Couldn't get petition JSON - #{textStatus}: #{errorThrown}")
      success: (petitionJson, _textStatus, _jqXHR) ->
        petitionData = new PetitionData(petitionJson)
        setupTitle(petitionData)
        window.chart = new Chart(petitionData)
        window.chart.draw()
