library(devtools)
load_all(".")
driver <- resolve_default_driver("gemini_image")
driver$output_dir <- "vignettes/images"
res <- driver$call("A beautiful view of Victoria Peak in Hong Kong", cli_opts = list(filename = "test_image.png"))
print(res)
list.files("vignettes/images")
