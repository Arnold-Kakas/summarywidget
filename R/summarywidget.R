#' Show a single summary statistic in a widget
#'
#' A `summarywidget` displays a single statistic derived from a linked table.
#' Its primary use is with the `crosstalk` package. Used with `crosstalk`,
#' a `summarywidget` displays a value which updates as the data selection
#' changes.
#'
#' @param data Data to summarize, normally an instance of [crosstalk::SharedData].
#' @param statistic The statistic to compute.
#' @param column For `sum` and `mean` statistics, the column of `data` to summarize.
#' Not used for `count` statistic.
#' @param selection Expression to select a fixed subset of `data`. May be
#' a logical vector or a one-sided formula that evaluates to a logical vector.
#' If used, the `key` given to [crosstalk::SharedData] must be a fixed column (not row numbers).
#' @param digits Number of decimal places to display, or NULL to display full precision.
#'
#' @import crosstalk
#' @import htmlwidgets
#'
#' @export
#' @seealso \url{https://kent37.github.io/summarywidget}
summarywidget <- function(data,
                          statistic = c("count", "sum", "mean", "min", "max", "rate", "distinct_count", "duplicates"), 
                          column = NULL,
                          selection = NULL, 
                          numerator = NULL, 
                          denominator = NULL,
                          selector = NULL,
                          digits = 0,
                          big_mark = " ",
                          width = NULL, 
                          height = NULL, 
                          elementId = NULL) {
  
  # Ensure valid inputs for "rate"
  if (statistic == "rate" && is.null(selector)) {
    stop("For 'rate', the 'selector' argument must be provided.")
  }
  
  # Handle Crosstalk compatibility
  if (crosstalk::is.SharedData(data)) {
    key <- data$key()
    group <- data$groupName()
    data <- data$origData()
  } else {
    key <- NULL
    group <- NULL
  }

  # Check if selection is provided and apply it
  if (!is.null(selection)) {
    if (inherits(selection, 'formula')) {
      if (length(selection) != 2L)
        stop("Unexpected two-sided formula: ", deparse(selection))
      selection = eval(selection[[2]], data, environment(selection))
    }

    if (!is.logical(selection))
      stop("Selection must contain TRUE/FALSE values.")
    data = data[selection,]
    key = key[selection]
  }

  # Ensure column is valid
  if (is.null(column) && !(statistic %in% c('count', 'distinct_count', 'duplicates'))) {
    stop("Column must be provided for ", statistic, " statistic.")
  }
  if (!is.null(column) && !(column %in% colnames(data))) {
    stop("No ", column, " column in data.")
  }

  # Prepare data for JavaScript
  js_data <- data
  if (!is.null(column)) {
    js_data <- data[[column]]
  }

  x = list(
    data = js_data,
    settings = list(
      statistic = statistic,
      digits = digits,
      big_mark = big_mark,
      numerator = numerator,
      denominator = denominator,
      selector = selector,
      crosstalk_key = key,
      crosstalk_group = group
    )
  )

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
