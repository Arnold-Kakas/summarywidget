HTMLWidgets.widget({
  name: 'summarywidget',
  type: 'output',

  factory: function(el, width, height) {

    return {
      renderValue: function(x) {

        var data = x.data; // Use provided data directly
        var value = 0;

        // Calculate statistics
        switch (x.settings.statistic) {
          case 'count':
            value = data.length;
            break;

          case 'sum':
            value = data.reduce((acc, val) => acc + val, 0);
            break;

          case 'mean':
            value = data.reduce((acc, val) => acc + val, 0) / data.length;
            break;

          case 'distinct_count':
            value = new Set(data).size;
            break;

          case 'duplicates':
            const uniqueSet = new Set();
            const duplicatesSet = new Set();
            data.forEach(val => {
              if (uniqueSet.has(val)) {
                duplicatesSet.add(val);
              } else {
                uniqueSet.add(val);
              }
            });
            value = duplicatesSet.size;
            break;

          case 'min':
            value = Math.min(...data);
            break;

          case 'max':
            value = Math.max(...data);
            break;

          case 'rate':

            if (!x.settings.selector || !x.settings.numerator) {
                console.error("For 'rate', 'selector' and 'numerator' must be specified.");
                return;
            }
            const rateType = x.settings.rate_type || "count_rate";
        
            const numeratorData = data.filter(val =>
                x.settings.numerator.includes(val.selector)
            );
        
            const denominatorData = x.settings.denominator
                ? data.filter(val => x.settings.denominator.includes(val.selector))
                : data; // Use full dataset if denominator not specified
        
            if (rateType === "count_rate") {
                const numeratorUnique = new Set(numeratorData.map(val => val.id)).size;
                const denominatorUnique = new Set(denominatorData.map(val => val.id)).size;
                value = denominatorUnique > 0 ? (numeratorUnique / denominatorUnique) * 100 : 0;
            } else if (rateType === "numeric_rate") {
                const numeratorSum = numeratorData.reduce((sum, val) => sum + val.id, 0);
                const denominatorSum = denominatorData.reduce((sum, val) => sum + val.id, 0);
                value = denominatorSum > 0 ? (numeratorSum / denominatorSum) * 100 : 0;
            }
            break;


          default:
            console.error('Invalid statistic specified:', x.settings.statistic);
            return;
        }

        // Formatting options
        const numberWithSep = (num, sep = ",") => {
          return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, sep);
        };

        if (x.settings.digits !== null) {
          value = parseFloat(value).toFixed(x.settings.digits);
        }
        if (x.settings.big_mark) {
          value = numberWithSep(value, x.settings.big_mark);
        }
        if (x.settings.statistic === 'rate') {
          value = `${value}%`;
        }

        el.innerText = value;
      },

      resize: function(width, height) {
        // Handle resizing if necessary
      }
    };
  }
});
