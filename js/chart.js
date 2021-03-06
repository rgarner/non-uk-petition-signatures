// Generated by CoffeeScript 1.9.3
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  String.prototype.capitalizeFirstLetter = function() {
    return this.charAt(0).toUpperCase() + this.slice(1);
  };

  this.Chart = (function() {
    var margin;

    margin = {
      top: 40,
      right: 70,
      bottom: 150,
      left: 70
    };

    function Chart(data, xAxisLabels, options) {
      this.data = data;
      this.xAxisLabels = xAxisLabels;
      this.options = options != null ? options : {
        toShow: 25
      };
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
      this.x || (this.x = d3.scale.ordinal().domain(this.xAxisLabels));
      this.x.rangeBands([0, this.width]);
      this.y || (this.y = d3.scale.linear().domain([0, d3.max(this.data)]));
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
      this.drawYAxis().append("text").attr("transform", "rotate(-90)").attr("y", -63).attr("dy", ".71em").style("text-anchor", "end").text("Signatures");
      return this.setupSignatureCounts();
    };

    Chart.prototype.replace = function() {
      $('#chartContainer #chart').remove();
      return $('#chartContainer').append('<svg id="chart" />');
    };

    return Chart;

  })();

}).call(this);

//# sourceMappingURL=chart.js.map
