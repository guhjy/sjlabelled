#' @title Retrieve variable label(s) of labelled data
#' @name get_label
#'
#' @description This function returns the variable labels of labelled data.
#'
#' @seealso See vignette \href{../doc/intro_sjlabelled.html}{Labelled Data and the sjlabelled-Package}
#'            for more details; \code{\link{set_label}} to manually set variable labels or \code{\link{get_labels}}
#'            to get value labels; \code{\link{var_labels}} to set multiple variable
#'            labels at once.

#' @param x A data frame with variables that have label attributes (e.g.
#'          from an imported SPSS, SAS or STATA data set, via \code{\link{read_spss}},
#'          \code{\link{read_sas}} or \code{\link{read_stata}}); a variable
#'          (vector) with variable label attribute; or a \code{list} of variables
#'          with variable label attributes. See 'Examples'.
#' @param ... Optional, names of variables, where labels should be retrieved.
#'            Required, if either data is a data frame and no vector, or if only
#'            selected variables from \code{x} should be used in the function.
#'            Convenient argument to work with pipe-chains (see 'Examples').
#' @param def.value Optional, a character string which will be returned as label
#'          if \code{x} has no label attribute. By default, \code{NULL} is returned.
#'
#' @inheritParams get_term_labels
#'
#' @return A named character vector with all variable labels from the data frame or list;
#'           or a simple character vector (of length 1) with the variable label, if \code{x} is a variable.
#'           If \code{x} is a single vector and has no label attribute, the value
#'           of \code{def.value} will be returned (which is by default \code{NULL}).
#'
#' @details See 'Details' in \code{\link{get_labels}}.
#'
#' @note \code{\link{var_labels}} is an alternative way to set variable labels,
#'       which follows the philosophy of tidyvers API design (data as first argument,
#'       dots as value pairs indicating variables)
#'
#' @examples
#' # import SPSS data set
#' # mydat <- read_spss("my_spss_data.sav", enc="UTF-8")
#'
#' # retrieve variable labels
#' # mydat.var <- get_label(mydat)
#'
#' # retrieve value labels
#' # mydat.val <- get_labels(mydat)
#'
#' data(efc)
#'
#' # get variable lable
#' get_label(efc$e42dep)
#'
#' # alternative way
#' get_label(efc)["e42dep"]
#'
#' # 'get_label()' also works within pipe-chains
#' efc %>% get_label(e42dep, e16sex)
#'
#' # set default values
#' get_label(mtcars, mpg, cyl, def.value = "no var labels")
#'
#' # simple barplot
#' barplot(table(efc$e42dep))
#' # get value labels to annotate barplot
#' barplot(table(efc$e42dep),
#'         names.arg = get_labels(efc$e42dep),
#'         main = get_label(efc$e42dep))
#'
#' # get labels from multiple variables
#' get_label(list(efc$e42dep, efc$e16sex, efc$e15relat))
#'
#' # use case conversion for human-readable labels
#' data(iris)
#' get_label(iris, def.value = colnames(iris))
#' get_label(iris, def.value = colnames(iris), case = "parsed")
#'
#' @export
get_label <- function(x, ..., def.value = NULL, case = NULL) {
  # evaluate arguments, generate data
  x <- get_dot_data(x, dplyr::quos(...))
  # auto-detect variable label attribute
  attr.string <- getVarLabelAttribute(x)

  # do we have a df?
  if (is.data.frame(x)) {
    # if yes, check if we have attached label table
    # from foreign import
    labels <- attr(x, "variable.labels", exact = T)

    # if not, get labels from each single vector
    if (is.null(labels)) {
      # iterate df
      labels <- sapply(seq_along(x), function(i) {
        # get label
        if (!is.null(attr.string))
          label <- attr(x[[i]], attr.string, exact = T)
        else
          label <- NULL

        # any label?
        if (!is.null(label)) {
          # name label
          names(label) <- colnames(x)[i]
          # append to return result
          return(convert_case(label, case))
        } else if (!is.null(def.value)) {
          # def.value may also apply to data frame arguments,
          # so it can be greater than length one
          if (i <= length(def.value))
            return(convert_case(def.value[i], case))
          else
            return(convert_case(def.value, case))
        } else {
          return("")
        }
      })
    }
    return(labels)
  } else if (is.list(x)) {
    # nothing found? then leave...
    if (is.null(attr.string)) return(NULL)
    # return attribute of all variables
    return(convert_case(unlist(lapply(x, attr, attr.string, exact = T)), case))
  } else {
    # nothing found? then leave...
    if (is.null(attr.string)) return(convert_case(def.value, case))

    # else return attribute
    retat <- attr(x, attr.string, exact = T)

    # still NULL? than use default return value
    if (is.null(retat)) retat <- def.value
    return(convert_case(retat, case))
  }
}
