HTMLWidgets.widget({
  name: 'summarywidget',
  type: 'output',

  factory: function(el, width, height) {

    // Function to filter data based on keys
    var filterDataByKeys = function(data, keys) {
      var result = [];
      var keySet = new Set(keys);
      for (var i = 0; i < data.length; i++) {
        if (keySet.has(data[i].key)) {
          result.push(data[i]);
        }
      }
      return result;
    };

    return {
      renderValue: function(x) {

        // Prepare data array
        var data = [];
        var i;
        for (i = 0; i < x.data.length; i++) {
          data.push({
            value: x.data[i],
            key: x.key ? x.key[i] : i,
            numerator_flag: x.numerator_flag ? x.numerator_flag[i] : null,
            denominator_flag: x.denominator_flag ? x.denominator_flag[i] : null,
            numerator_value: x.numerator_value ? x.numerator_value[i] : null,
            denominator_value: x.denominator_value ? x.denominator_value[i] : null
          });
        }

        // Function to update the display
        var update = function(filteredData) {
          var values = filteredData.map(function(d) { return d.value; });

          var value = 0;
          switch (x.settings.statistic) {
            case 'count':
              value = values.length;
              break;
            case 'sum':
              value = values.reduce(function(acc, val) { return acc + val; }, 0);
              break;
            case 'mean':
              value = values.reduce(function(acc, val) { return acc + val; }, 0) / values.length;
              break;
            case 'distinct_count':
              value = [...new Set(values)].length;
              break;
            case 'duplicates':
              const uniqueValues = new Set();
              const duplicates = new Set();
              values.forEach(val => {
                if (uniqueValues.has(val)) duplicates.add(val);
                else uniqueValues.add(val);
              });
              value = duplicates.size;
              break;
            case 'min':
              value = Math.min(...values);
              break;
            case 'max':
              value = Math.max(...values);
              break;
            case 'count_rate':
              var numeratorCount = 0;
              var denominatorCount = 0;
              for (var i = 0; i < filteredData.length; i++) {
                var d = filteredData[i];
                if (d.denominator_flag) {
                  denominatorCount++;
                  if (d.numerator_flag) {
                    numeratorCount++;
                  }
                }
              }
              value = denominatorCount === 0 ? 0 : (numeratorCount / denominatorCount * 100);
              break;
            case 'numeric_rate':
              var numeratorSum = 0;
              var denominatorSum = 0;
              for (var i = 0; i < filteredData.length; i++) {
                var d = filteredData[i];
                if (d.denominator_flag) {
                  denominatorSum += d.denominator_value;
                  if (d.numerator_flag) {
                    numeratorSum += d.numerator_value;
                  }
                }
              }
              value = denominatorSum === 0 ? 0 : (numeratorSum / denominatorSum * 100);
              break;
            default:
              console.error('Invalid statistic specified:', x.settings.statistic);
              return;
          }

          // Function to format numbers with thousand separators
          function numberWithSep(x, bigMark = ",") {
            if (typeof x !== "string") {
              x = x.toString();
            }
            var pattern = /(-?\d+)(\d{3})/;
            while (pattern.test(x)) {
              x = x.replace(pattern, `$1${bigMark}$2`);
            }
            return x;
          }

          // Apply formatting
          if (x.settings.digits !== null) {
            value = parseFloat(value).toFixed(x.settings.digits);
          }
          if (x.settings.big_mark) {
            value = numberWithSep(value, x.settings.big_mark);
          }
          if (x.settings.statistic === 'count_rate' || x.settings.statistic === 'numeric_rate') {
            value = value + '%';
          }

          el.innerText = value;
        };

        // Function to get filtered data considering Crosstalk filters and selections
        var updateFilteredData = function() {
          var keys = null;
          if (ct_filter.filteredKeys && ct_sel.value) {
            // Intersection of filter and selection
            keys = ct_filter.filteredKeys.filter(function(k) { return ct_sel.value.includes(k); });
          } else if (ct_filter.filteredKeys) {
            keys = ct_filter.filteredKeys;
          } else if (ct_sel.value) {
            keys = ct_sel.value;
          }

          var filteredData;
          if (keys) {
            filteredData = filterDataByKeys(data, keys);
          } else {
            filteredData = data;
          }

          update(filteredData);
        };

        // Set up Crosstalk filters
        var ct_filter = new crosstalk.FilterHandle();
        ct_filter.setGroup(x.settings.crosstalk_group);
        ct_filter.on("change", function(e) {
          updateFilteredData();
        });

        var ct_sel = new crosstalk.SelectionHandle();
        ct_sel.setGroup(x.settings.crosstalk_group);
        ct_sel.on("change", function(e) {
          updateFilteredData();
        });

        // Initial update
        updateFilteredData();
      },

      resize: function(width, height) {
        // Code to handle resizing if necessary
      }

    };
  }
});
