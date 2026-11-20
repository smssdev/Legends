variable "app_version" {
  # which release runs: the pipeline sets it to the image's commit
  type    = string
  default = "v1"
}

variable "app_copies" {
  type    = number
  default = 2
}

variable "db_password" {
  # never a password in the code: it arrives as a variable, from the pipeline's secret store
  type      = string
  sensitive = true
}
