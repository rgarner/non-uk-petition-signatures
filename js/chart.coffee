class Chart
  TOP = 10

  constructor: (@petition_json) ->

  signaturesByCountry: () =>
    @petition_json.data.attributes.signatures_by_country.filter (country) ->
      country.code != 'GB'

  signaturesByCountryDescendingCount: () =>
    descending = @signaturesByCountry().sort (prev, current) ->
      if current.signature_count > prev.signature_count then 1 else -1
    descending[0..TOP - 1]

  maxCountryFrequency: () =>
    @signaturesByCountryDescendingCount()[0].signature_count

  draw: () =>
    margin = { top: 40, right: 70, bottom: 150, left: 70 }
    width = window.innerWidth - margin.left - margin.right
    height = 550 - margin.top - margin.bottom

    signaturesByCountry = @signaturesByCountryDescendingCount()
    data = signaturesByCountry.map (country) -> country.signature_count
    countryLabels = signaturesByCountry.map (country) -> country.code

    barWidth = width / data.length

    x = d3.scale.ordinal()
      .domain(countryLabels)
      .rangeBands([0, width])

    y = d3.scale.linear()
      .domain([0, @maxCountryFrequency()])
      .range([height, 0])

    xAxis = d3.svg.axis().scale(x).orient("bottom")
    yAxis = d3.svg.axis().scale(y).orient("left")

    svg = d3.select("#chart").append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis)
      .selectAll("text")
      .attr("transform", "rotate(90)")
      .attr("x", 15)
      .attr("y", 0)
      .style("text-anchor", "start");

    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", -63)
      .attr("dy", ".71em")
      .style("text-anchor", "end")
      .text("Signatures")

    bar = svg.selectAll(".bar")
      .data(data)
      .enter().append("rect")
      .attr("class", "bar")
      .attr("width", barWidth - 1)
      .attr("height", (d) -> height - y(d) )
      .attr("x", (d, i) -> i * barWidth)# x(countryLabels[i]))
      .attr("y", (d) -> y(d))

    bar.append("rect")

setupTitle = (countries) ->
  uk = (c for c in countries when c.code is 'GB')[0]
  formattedSignatureCount = uk.signature_count.toLocaleString('en-GB', {minimumFractionDigits: 0});
  $('.uk-signatures').text("(#{formattedSignatureCount} signatures)")

jQuery ->
  if document.getElementById('chart')
    $.ajax
      url: "https://petition.parliament.uk/petitions/171928.json"
      dataType: "json"
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("Couldn't get petition JSON - #{textStatus}: #{errorThrown}")
      success: (petitionData, _textStatus, _jqXHR) ->
        setupTitle(petitionData.data.attributes.signatures_by_country)
        window.chart = new Chart(petitionData)
        window.chart.draw()
