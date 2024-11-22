#' Show a single summary statistic in a widget
#'
#' A `summarywidget` displays a single statistic derived from a linked table.
#' Its primary use is with the `crosstalk` package. Used with `crosstalk`,
#' a `summarywidget` displays a value which updates as the data selection
#' changes.
#'
#' @param data Data to summarize, normally an instance of [crosstalk::SharedData].
#' @param statistic The statistic to compute.
#' @param column For `sum`, `mean`, `numeric_rate` statistics, the column of `data` to summarize.
#' Not used for `count`, `distinct_count`, `duplicates`, or `count_rate` statistics.
#' @param selection Expression to select a fixed subset of `data`. May be
#' a logical vector or a one-sided formula that evaluates to a logical vector.
#' If used, the `key` given to [crosstalk::SharedData] must be a fixed column (not row numbers).
#' @param numerator_selection Expression to select the numerator subset of `data` for rate calculations.
#' @param denominator_selection Expression to select the denominator subset of `data` for rate calculations.
#' If NULL, the entire data is used as the denominator.
#' @param numerator_column Column to use for the numerator in `numeric_rate` statistic.
#' @param denominator_column Column to use for the denominator in `numeric_rate` statistic.
#' If NULL, `numerator_column` is used.
#' @param digits Number of decimal places to display, or NULL to display full precision.
#' @param big_mark Character used as thousands separator.
#' @param prefix String to prepend to the value. Default is NULL.
#' @param suffix String to append to the value. Default is NULL. Not applied for rate statistics.
#' @param width Width of the widget.
#' @param height Height of the widget.
#' @param elementId Element ID for the widget.
#'
#' @import crosstalk
#' @import htmlwidgets
#'
#' @export
summarywidget <- function(data,
                          statistic = c("count", "sum", "mean", "min", "max", "distinct_count", "duplicates", "count_rate", "numeric_rate"),
                          column = NULL,
                          selection = NULL,
                          numerator_selection = NULL,
                          denominator_selection = NULL,
                          numerator_column = NULL,
                          denominator_column = NULL,
                          digits = 0,
                          big_mark = " ",
                          prefix = NULL,
                          suffix = NULL,
                          width = NULL, height = NULL, elementId = NULL) {

  if (crosstalk::is.SharedData(data)) {
    # Using Crosstalk
    key <- data$key()
    group <- data$groupName()
    data <- data$origData()
  } else {
    # Not using Crosstalk
    warning("summarywidget works best when data is an instance of crosstalk::SharedData.")
    key <- NULL
    group <- NULL
  }

  statistic <- match.arg(statistic)

  # If selection is given, apply it
  if (!is.null(selection)) {
    # Evaluate any formula
    if (inherits(selection, 'formula')) {
      if (length(selection) != 2L)
        stop("Unexpected two-sided formula: ", deparse(selection))
      selection <- eval(selection[[2]], data, environment(selection))
    }

    if (!is.logical(selection))
      stop("Selection must contain TRUE/FALSE values.")
    data <- data[selection, ]
    key <- key[selection]
  }

  # We need to handle numerator and denominator selections
  numerator_flag <- NULL
  denominator_flag <- NULL

  # Prepare the main data value
  if (is.null(column)) {
    if (statistic %in% c('sum', 'mean', 'min', 'max', 'numeric_rate'))
      stop("Column must be provided with ", statistic, " statistic.")
    data_value <- seq_len(nrow(data))  # Use row indices for count-based statistics
  } else {
    if (!(column %in% colnames(data)))
      stop("No ", column, " column in data.")
    data_value <- data[[column]]
  }

  if (statistic %in% c('count_rate', 'numeric_rate')) {

    # Numerator selection
    if (!is.null(numerator_selection)) {
      if (inherits(numerator_selection, 'formula')) {
        if (length(numerator_selection) != 2L)
          stop("Unexpected two-sided formula: ", deparse(numerator_selection))
        numerator_flag <- eval(numerator_selection[[2]], data, environment(numerator_selection))
      } else {
        numerator_flag <- numerator_selection
      }
      if (!is.logical(numerator_flag))
        stop("numerator_selection must contain TRUE/FALSE values.")
    } else {
      stop("numerator_selection must be provided for ", statistic, " statistic.")
    }

    # Denominator selection
    if (!is.null(denominator_selection)) {
      if (inherits(denominator_selection, 'formula')) {
        if (length(denominator_selection) != 2L)
          stop("Unexpected two-sided formula: ", deparse(denominator_selection))
        denominator_flag <- eval(denominator_selection[[2]], data, environment(denominator_selection))
      } else {
        denominator_flag <- denominator_selection
      }
      if (!is.logical(denominator_flag))
        stop("denominator_selection must contain TRUE/FALSE values.")
    } else {
      # Use all data as denominator
      denominator_flag <- rep(TRUE, nrow(data))
    }

    if (statistic == 'numeric_rate') {
      # For 'numeric_rate', we need to specify numerator_column and denominator_column
      if (is.null(numerator_column))
        stop("numerator_column must be provided for numeric_rate statistic.")

      if (!(numerator_column %in% colnames(data)))
        stop("No ", numerator_column, " column in data.")

      if (is.null(denominator_column))
        denominator_column <- numerator_column  # Use same column if denominator_column not provided

      if (!(denominator_column %in% colnames(data)))
        stop("No ", denominator_column, " column in data.")

      data$numerator_value <- data[[numerator_column]]
      data$denominator_value <- data[[denominator_column]]
    } else {
      data$numerator_value <- NULL
      data$denominator_value <- NULL
    }
  }

  # Prepare data to pass to JavaScript
  x <- list(
    data = data_value,
    key = key,
    numerator_flag = numerator_flag,
    denominator_flag = denominator_flag,
    numerator_value = if (!is.null(data$numerator_value)) data$numerator_value else NULL,
    denominator_value = if (!is.null(data$denominator_value)) data$denominator_value else NULL,
    settings = list(
      statistic = statistic,
      digits = digits,
      big_mark = big_mark,
      prefix = prefix,
      suffix = suffix,
      crosstalk_group = group
    )
  )

  # Create widget
  htmlwidgets::createWidget(
    name = 'summarywidget',
    x,
    width = width,
    height = height,
    package = 'summarywidget',
    elementId = elementId,
    dependencies = crosstalk::crosstalkLibs()
  )
}


#' Shiny bindings for summarywidget
#'
#' Output and render functions for using summarywidget within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a summarywidget
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name summarywidget-shiny
#'
#' @export
summarywidgetOutput <- function(outputId, width = '100%', height = '400px'){
  htmlwidgets::shinyWidgetOutput(outputId, 'summarywidget', width, height, package = 'summarywidget')
}

#' @rdname summarywidget-shiny
#' @export
renderSummarywidget <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, summarywidgetOutput, env, quoted = TRUE)
}

# Use a <span> container rather than the default <div>
summarywidget_html <- function(id, style, class, ...){
  htmltools::tags$span(id = id, class = class)
}
