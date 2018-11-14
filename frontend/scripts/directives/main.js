'use strict';

function dropzone() {
  return {
      restrict: 'EA',
      scope: {
        chartData: '='
      },
      link: function(scope, element, attrs) {
        var config = {
            url: 'http://162.209.96.234:5000/upload',
            //url: 'http://localhost:5000/upload',
            maxFilesize: 100,
            paramName: "uploadfile",
            maxThumbnailFilesize: 10,
            parallelUploads: 1,
            thumbnailWidth: 210,
            thumbnailHeight: 210,
            autoProcessQueue: true
        };

        var eventHandlers = {
            'addedfile': function(file) {
                scope.file = file;
                if (this.files[1]!=null) {
                    this.removeFile(this.files[0]);
                }
                scope.$apply(function() {
                    scope.fileAdded = true;
                });
            },

            'success': function (file, response) {
                var cls = JSON.parse(response[1]);
                scope.chartData = cls;
                scope.$emit('clicked-from-directive', [response[0], cls])
            }
        };

        var mydropzone = new Dropzone(element[0], config);

        angular.forEach(eventHandlers, function(handler, event) {
            mydropzone.on(event, handler);
        });

        scope.processDropzone = function() {
            mydropzone.processQueue();
        };

        scope.resetDropzone = function() {
            mydropzone.removeAllFiles();
        }
    }
  }
}

function dropzone2() {
  return {
      restrict: 'EA',
      scope: {
        count: '='
      },
      link: function(scope, element, attrs) {
        var config = {
            url: 'http://162.209.96.234:5001/upload',
            maxFilesize: 100,
            paramName: "uploadfile",
            maxThumbnailFilesize: 10,
            parallelUploads: 1,
            thumbnailWidth: 210,
            thumbnailHeight: 210,
            autoProcessQueue: true
        };

        var eventHandlers = {
            'addedfile': function(file) {
                scope.file = file;
                if (this.files[1]!=null) {
                    this.removeFile(this.files[0]);
                }
                scope.$apply(function() {
                    scope.fileAdded = true;
                });
            },

            'sending' : function (file, xhr, formData) {
              //var s = $('#stylenumber').val();
              var s = scope.$parent.itemSelected.id
              formData.append("style", s);
            },

            'success': function (file, response) {
                scope.$emit('clicked-from-directive2', [response[0], response[1]])
            }
        };

        var mydropzone = new Dropzone(element[0], config);

        angular.forEach(eventHandlers, function(handler, event) {
            mydropzone.on(event, handler);
        });

        scope.processDropzone = function() {
            mydropzone.processQueue();
        };

        scope.resetDropzone = function() {
            mydropzone.removeAllFiles();
        }
    }
  }
}

angular.module('owlDemoApp')
  .directive('linearChart', function($parse, $window){
    return{
      restrict:'EA',
      template:"<svg width='620' height='200'></svg>",
      link: function(scope, elem, attrs){
        var exp = $parse(attrs.chartData);
        var salesDataToPlot=exp(scope);
        var padding = 20;
        var pathClass="path";

        var d3 = $window.d3;
        var rawSvg=elem.find('svg');
        var svg = d3.select(rawSvg[0]).append('svg').style('width', '100%');

        /*
        window.oneresize = function() {
          scope.$apply();
        }

        scope.$watch(function() {
          return angular.element($window)[0].innerWidth;
        }, function() {
          console.log("fuck!!");
          drawLineChart();
        }) */

        var w = rawSvg.attr("width");
        var h = rawSvg.attr("height");
        //console.log("initial w and h:", w, h);
        var margin = {top: 20, right: 30, bottom: 40, left: 30};
        var width  = w - margin.left - margin.right;
        var height = h - margin.top - margin.bottom;
        var color  = d3.scale.category20();

        var xScale = d3.scale.linear()
          .range([padding + (width / 2), width - padding])
          .domain([0, 1.0]);
        var xAxisGen = d3.svg.axis().scale(xScale).orient("bottom");

        svg.append("g")
          .attr("class", "x axis")
          .attr("transform", "translate(0," + height + ")")
          .call(xAxisGen);


        function wrap(text, width) {
          text.each(function() {
            var text = d3.select(this),
              words = text.text().split(/\s+/).reverse(),
              word,
              line = [],
              lineNumber = 0,
              lineHeight = 1.1, // ems
              y = text.attr("y"),
              dy = parseFloat(text.attr("dy")),
              tspan = text.text(null).append("tspan").attr("x", -10).attr("y", y).attr("dy", dy + "em");

            while (word = words.pop()) {
              line.push(word);
              tspan.text(line.join(" "));
              if (tspan.node().getComputedTextLength() > width) {
                line.pop();
                tspan.text(line.join(" "));
                line = [word];
                tspan = text.append("tspan")
                  .attr("x", 0)
                  .attr("y", y)
                  .attr("dy", ++lineNumber * lineHeight + dy + "em")
                  .text(word);
              }
            }
          });
        }

        function drawLineChart() {
          svg.selectAll("*").remove();
          salesDataToPlot.sort((a, b) => b.prop - a.prop);

          var yScale = d3.scale.ordinal().rangeRoundBands([0, height], 0.1);
          yScale.domain(salesDataToPlot.map(function(d) { return d.class; }));

          var yAxisGen = d3.svg.axis()
            .scale(yScale)
            .orient("left")
            .tickSize(0)
            .tickPadding(6);

          svg.select(".y").remove();
          svg.append("g")
            .attr("class", "y axis")
            .attr("transform", "translate(" + xScale(0) + ",0)")
            .call(yAxisGen)//;
            .selectAll(".y text")
            .call(wrap, (width / 2));


          var bars = svg.selectAll(".bar").data(salesDataToPlot);

          bars
            .enter().append("rect")
            .attr("class", function(d) { return "bar bar--" + (d.prop < 0 ? "negative" : "positive"); }); // Do NOT connect this part to the next. VERY IMPORTANT!!!

          bars
            .attr("x", function(d) { return xScale(Math.min(0, d.prop)); })
            .attr("y", function(d) { return yScale(d.class); })
            .attr("width", function(d) { return Math.abs(xScale(d.prop) - xScale(0)); })
            .attr('fill', function(d) { return color(d.prop); })
            .attr("height", yScale.rangeBand());


          bars
            .enter()
            .append("text")
            .attr("fill", "#fff")
            .attr("y", function(d, i) {return i * 26 + 25;})
            .attr("x", function(d) { return xScale(d.prop) + 20; })
            .text(function(d){return (d.prop * 100).toFixed(1) + '%';});
        }


        /*
        d3.select(window).on('resize', resize);

        function resize() {
          //w = rawSvg.attr("width"); --> fixed from the template.
          //h = rawSvg.attr("height");
          //w = $window.innerWidth; --> changed, but it's the outer size;
          //h = $window.innerHeight;
          console.log(w, h);
          width  = w - margin.left - margin.right;
          height = h - margin.top - margin.bottom;
          xScale = d3.scale.linear()
            .range([padding + (width / 2), width - padding])
            .domain([0, 1.0]);
          xAxisGen = d3.svg.axis().scale(xScale).orient("bottom");
          drawLineChart();
        }
        */

        scope.$watchCollection(exp, function(newVal, oldVal){
          salesDataToPlot = newVal;
          drawLineChart();
        });

        drawLineChart();
      }
    }
});

angular.module('owlDemoApp')
  .directive('dropzone', dropzone)

angular.module('owlDemoApp')
  .directive('dropzone2', dropzone2)
