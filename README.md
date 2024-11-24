SummaryWidget is an [HTML widget](http://www.htmlwidgets.org) which works with
[Crosstalk](https://rstudio.github.io/crosstalk/index.html) to display a single
summary statistic. The statistic updates when the Crosstalk selection changes. A SummaryWidget can display the count, sum or mean of one column of selected data.
It can also have a fixed filter that selects a subset of the full dataset.

## New Features

We've expanded the functionality of SummaryWidget to include additional statistics and formatting options:

### Additional Statistics

- **min**: Displays the minimum value of the selected data.
- **max**: Shows the maximum value of the selected data.
- **distinct_count**: Counts the number of unique values in the selected data.
- **duplicates**: Returns the number of duplicated records.
- **count_rate**: Calculates the rate based on counts (e.g., the share of new customers from the total), multiplied by 100 to express it as a percentage.
- **numeric_rate**: Computes the rate of a numeric metric for a specific group (e.g., the rate of sales from new customers out of total sales), also expressed as a percentage.

### Formatting Options

- **prefix**: A string to display before the statistic (e.g., "$" for currency).
- **suffix**: A string to display after the statistic. For rate calculations, the suffix is automatically set to "%" and any custom suffix is ignored.
- **big_mark**: Character used as a thousands separator. The default is a space (" ").


For more information and examples see the
[full documentation](https://kent37.github.io/summarywidget).
