library(testthat)
library(httr2)
source("R/driver.R")
source("R/drivers_api.R")
source("R/utils.R")

test_that('API error', {
  drv <- OpenAIDriver$new()
  withr::with_envvar(list(OPENAI_API_KEY = 'test'), {
    httr2::with_mocked_responses(
      function(req) httr2::response(status_code = 500),
      {
        expect_error(drv$call('Hello'))
      }
    )
  })
})
