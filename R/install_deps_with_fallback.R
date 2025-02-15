install_deps_with_fallback <- function() {
  deps <- remotes::dev_package_deps(dependencies = TRUE)
  deps <- deps[!is.na(deps$package), ]  # Remove rows with missing package names
  saveRDS(deps, ".github/depends.Rds", version = 2)
  writeLines(sprintf("R-%i.%i", getRversion()$major, getRversion()$minor), ".github/R-version")
}

install_deps_with_fallback()
