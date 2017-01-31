// Generated by CoffeeScript 1.9.3
(function() {
  var Chart,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Chart = (function() {
    var margin;

    margin = {
      top: 40,
      right: 70,
      bottom: 150,
      left: 70
    };

    function Chart(petitionData1) {
      this.petitionData = petitionData1;
      this.replace = bind(this.replace, this);
      this.draw = bind(this.draw, this);
      this.chartGroup = bind(this.chartGroup, this);
      this.svg = bind(this.svg, this);
      this.setupSignatureCounts = bind(this.setupSignatureCounts, this);
      this.drawYAxis = bind(this.drawYAxis, this);
      this.drawXAxis = bind(this.drawXAxis, this);
      this.yAxisGroup = bind(this.yAxisGroup, this);
      this.xAxisGroup = bind(this.xAxisGroup, this);
      this.recalculateScales = bind(this.recalculateScales, this);
      this.resize = bind(this.resize, this);
      this.countryLabels = this.petitionData.signaturesByCountryDescendingCount().map(function(country) {
        return country.name;
      });
      this.data = this.petitionData.signaturesByCountryDescendingCount().map(function(country) {
        return country.signature_count;
      });
      d3.select(window).on('resize', this.resize);
    }

    Chart.prototype.resize = function() {
      this.recalculateScales();
      this.drawXAxis();
      this.drawYAxis();
      return this.svg().selectAll('rect').attr('x', (function(_this) {
        return function(d, i) {
          return i * _this.barWidth;
        };
      })(this)).attr('width', this.barWidth - 1);
    };

    Chart.prototype.recalculateScales = function() {
      this.width = window.innerWidth - margin.left - margin.right;
      this.height = 550 - margin.top - margin.bottom;
      this.barWidth = this.width / this.data.length;
      this.x || (this.x = d3.scale.ordinal().domain(this.countryLabels));
      this.x.rangeBands([0, this.width]);
      this.y || (this.y = d3.scale.linear().domain([0, this.petitionData.maxCountryFrequency()]));
      return this.y.range([this.height, 0]);
    };

    Chart.prototype.xAxisGroup = function() {
      var xAxisGroup;
      xAxisGroup = d3.select('g.x.axis');
      if (!xAxisGroup.empty()) {
        return xAxisGroup;
      }
      return this.chartGroup().append("g").attr("class", "x axis");
    };

    Chart.prototype.yAxisGroup = function() {
      var yAxisGroup;
      yAxisGroup = d3.select('g.y.axis');
      if (!yAxisGroup.empty()) {
        return yAxisGroup;
      }
      return this.chartGroup().append("g").attr("class", "y axis");
    };

    Chart.prototype.drawXAxis = function() {
      return this.xAxisGroup().attr("transform", "translate(0," + this.height + ")").call(this.xAxis).selectAll("text").attr("transform", "rotate(90)").attr("x", 15).attr("y", 0).style("text-anchor", "start");
    };

    Chart.prototype.drawYAxis = function() {
      return this.yAxisGroup().call(this.yAxis);
    };

    Chart.prototype.setupSignatureCounts = function() {
      return this.chartGroup().selectAll(".bar").data(this.data).enter().append("rect").attr("class", "bar").attr("width", this.barWidth - 1).attr("height", (function(_this) {
        return function(d) {
          return _this.height - _this.y(d);
        };
      })(this)).attr("x", (function(_this) {
        return function(d, i) {
          return i * _this.barWidth;
        };
      })(this)).attr("y", (function(_this) {
        return function(d) {
          return _this.y(d);
        };
      })(this)).append("title").text(function(d) {
        return d + " signatures";
      });
    };

    Chart.prototype.svg = function() {
      return d3.select("#chart").attr("width", this.width + margin.left + margin.right).attr("height", this.height + margin.top + margin.bottom);
    };

    Chart.prototype.chartGroup = function() {
      var chartGroup;
      chartGroup = d3.select('.chart-group');
      if (!chartGroup.empty()) {
        return chartGroup;
      }
      return this.svg().append("g").attr("class", "chart-group").attr("transform", "translate(" + margin.left + "," + margin.top + ")");
    };

    Chart.prototype.draw = function() {
      this.recalculateScales();
      this.xAxis = d3.svg.axis().scale(this.x).orient("bottom");
      this.yAxis = d3.svg.axis().scale(this.y).orient("left");
      this.drawXAxis();
      this.xAxisGroup().selectAll('text').append('title').text((function(_this) {
        return function(c) {
          var signatures;
          signatures = _this.petitionData.signatureCountForName(c);
          return signatures + " signature" + (signatures > 1 ? 's' : '');
        };
      })(this));
      this.drawYAxis().append("text").attr("transform", "rotate(-90)").attr("y", -63).attr("dy", ".71em").style("text-anchor", "end").text("Signatures");
      return this.setupSignatureCounts();
    };

    Chart.prototype.replace = function() {
      $('#chartContainer #chart').remove();
      return $('#chartContainer').append('<svg id="chart" />');
    };

    return Chart;

  })();

  this.PageManager = (function() {
    function PageManager() {}

    PageManager.setup = function(petitionUrl) {
      return $.ajax({
        url: petitionUrl,
        dataType: "json",
        error: function(jqXHR, textStatus, errorThrown) {
          return console.log("Couldn't get petition JSON - " + textStatus + ": " + errorThrown);
        },
        success: function(petitionJson) {
          var petitionData;
          petitionData = new PetitionData(petitionJson);
          PageManager.setupTitle(petitionData);
          PageManager.setupCsvDownload(petitionData);
          if (window._chart) {
            window._chart.replace();
          }
          window._chart = new Chart(petitionData);
          return window._chart.draw();
        }
      });
    };

    PageManager.setupTitle = function(petitionData) {
      var formattedSignatureCount;
      $('.petition-title').text('');
      $('.petition-title a').remove();
      $('.petition-title').append('<a />');
      $('.petition-title a').text(petitionData.title()).attr('href', petitionData.url());
      formattedSignatureCount = petitionData.uk().signature_count.toLocaleString('en-GB', {
        minimumFractionDigits: 0
      });
      $('.uk-signatures a').remove();
      return $('.uk-signatures').text("(" + formattedSignatureCount + " UK signatures)");
    };

    PageManager.download = function(petitionData) {
      var ALL, country, csv, encodedUri, index, j, len, row, signaturesByCountry;
      console.log(petitionData);
      ALL = 500;
      signaturesByCountry = petitionData.signaturesByCountryDescendingCount(ALL);
      csv = "data:text/csv;charset=utf-8,country_code, country_name, signature_count\n";
      for (index = j = 0, len = signaturesByCountry.length; j < len; index = ++j) {
        country = signaturesByCountry[index];
        row = [country.code, country.name, country.signature_count].join(",");
        csv += row;
        if (index < signaturesByCountry.length) {
          csv += "\n";
        }
      }
      encodedUri = encodeURI(csv);
      return window.open(encodedUri);
    };

    PageManager.setupCsvDownload = function(petitionData) {
      return $('#download').click(function() {
        return PageManager.download(petitionData);
      });
    };

    return PageManager;

  })();

  jQuery(function() {
    if (document.getElementById('chart')) {
      return PageManager.setup("https://petition.parliament.uk/petitions/171928.json");
    }
  });

}).call(this);
