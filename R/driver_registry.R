# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        driver_registry.R
# Author:      APAF Agentic Workflow
# Purpose:     Centralized Driver Management & Hot-Swapping
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

#' Driver Registry R6 Class
#'
#' @description
#' A singleton-like registry for managing AgentDriver instances.
#' Enables runtime recovery and hot-swapping of drivers across nodes.
#'
#' @return A `DriverRegistry` R6 object.
#' @importFrom R6 R6Class
#' @export
DriverRegistry <- R6::R6Class("DriverRegistry",
  public = list(
    #' @field drivers List. Storage for registered drivers.
    drivers = list(),

    #' Initialize DriverRegistry
    #' @return A new `DriverRegistry` object.
    initialize = function() {
      self$drivers <- list()
    },

    #' Register a Driver
    #' @param driver AgentDriver object.
    #' @param overwrite Logical. Whether to overwrite existing driver with same ID.
    #' @return The registry object (invisibly).
    register = function(driver, overwrite = FALSE) {
      if (!inherits(driver, "AgentDriver")) {
        stop("Only objects inheriting from AgentDriver can be registered.")
      }

      id <- driver$id
      if (id %in% names(self$drivers) && !overwrite) {
        warning(sprintf("Driver with ID '%s' already registered. Use overwrite=TRUE to replace.", id))
        return(invisible(self))
      }

      self$drivers[[id]] <- driver
      invisible(self)
    },

    #' Get a Driver
    #' @param id String. Driver identifier.
    #' @return AgentDriver object or NULL.
    get = function(id) {
      if (id %in% names(self$drivers)) {
        return(self$drivers[[id]])
      }
      return(NULL)
    },

    #' List Registered Drivers
    #' @return Data frame of registered drivers and their metadata.
    list_drivers = function() {
      if (length(self$drivers) == 0) {
        return(data.frame(id = character(), provider = character(), model = character()))
      }

      data.frame(
        id = names(self$drivers),
        provider = purrr::map_chr(self$drivers, ~ .x$provider),
        model = purrr::map_chr(self$drivers, ~ .x$model_name),
        stringsAsFactors = FALSE
      )
    },

    #' Remove a Driver
    #' @param id String.
    #' @return The registry object (invisibly).
    remove = function(id) {
      self$drivers[[id]] <- NULL
      invisible(self)
    },

    #' Clear Registry
    #' @return The registry object (invisibly).
    clear = function() {
      self$drivers <- list()
      invisible(self)
    }
  )
)

#' Global Driver Registry Accessor
#' @return The global DriverRegistry instance.
#' @export
get_driver_registry <- function() {
  if (!exists(".HydraR_DriverRegistry", envir = .GlobalEnv)) {
    assign(".HydraR_DriverRegistry", DriverRegistry$new(), envir = .GlobalEnv)
  }
  get(".HydraR_DriverRegistry", envir = .GlobalEnv)
}

# <!-- APAF Bioinformatics | driver_registry.R | Approved | 2026-03-29 -->
