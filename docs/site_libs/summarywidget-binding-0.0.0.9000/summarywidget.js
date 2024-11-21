HTMLWidgets.widget({
  name: 'summarywidget',
  type: 'output',

  factory: function(el, width, height) {

    // Filter obj, returning a new obj containing only
    // values with keys in keys.
    var filterKeys = function(obj, keys) {
      var result = {};
      keys.forEach(function(k) {
        if (obj.hasOwnProperty(k))
          result[k]=obj[k];});
      return result;
    };

    return {
      renderValue: function(x) {

        // Make a data object with keys so we can easily update the selection
        var data = {};
        var i;
        if (x.settings.crosstalk_key === null) {
          for (i=0; i<x.data.length; i++) {
            data[i] = x.data[i];
          }
        } else {
          for (i=0; i<x.settings.crosstalk_key.length; i++) {
            data[x.settings.crosstalk_key[i]] = x.data[i];
          }
        }

        // Update the display to show the values in d
        var update = function(d) {
          // Get a simple vector. Don't use Object.values(), RStudio doesn't seem to support it.
          var values = [];
          for (var key in d) {
            if (d.hasOwnProperty(key)) { values.push(d[key]);}
          }

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
    default:
        console.error('Invalid statistic specified:', x.settings.statistic);
        return;
}

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

// Apply the digits formatting if specified
if (x.settings.digits !== null) {
    value = parseFloat(value).toFixed(x.settings.digits);
}

// Apply the big mark formatting if specified
if (x.settings.big_mark) {
    value = numberWithSep(value, x.settings.big_mark);
}

          el.innerText = value;
       };

       // Set up to receive crosstalk filter and selection events
       var ct_filter = new crosstalk.FilterHandle();
       ct_filter.setGroup(x.settings.crosstalk_group);
       ct_filter.on("change", function(e) {
         if (e.value) {
           update(filterKeys(data, e.value));
         } else {
           update(data);
         }
       });

       var ct_sel = new crosstalk.SelectionHandle();
       ct_sel.setGroup(x.settings.crosstalk_group);
       ct_sel.on("change", function(e) {
         if (e.value && e.value.length) {
           update(filterKeys(data, e.value));
         } else {
           update(data);
         }
       });

       update(data);
      },

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
