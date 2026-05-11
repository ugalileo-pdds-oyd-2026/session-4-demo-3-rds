variable "region" {
  type    = string
  default = "us-west-2"
}

variable "environment" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
