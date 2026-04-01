desc_lines <- readLines("DESCRIPTION")
collate_start <- grep("^Collate:", desc_lines)
if (length(collate_start) > 0) {
  # Add the missing files to Collate
  new_desc <- character(0)
  for(i in 1:length(desc_lines)) {
    new_desc <- c(new_desc, desc_lines[i])
    if(i == collate_start) {
      new_desc <- c(new_desc, "    'map_node.R'", "    'observer_node.R'", "    'router_node.R'")
    }
  }
  writeLines(new_desc, "DESCRIPTION")
}
