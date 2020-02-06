variable "region" {
  type = string
}

variable "email_addresses" {
  type        = "list"
  description = "Email address to send notifications to"
}

variable "protocol" {
  default     = "email"
  description = "SNS Protocol to use. email or email-json"
  type        = "string"
}

variable "create_test_instance" {
  type    = bool
  default = false
}
