variable "security_email" {
  type = string
  description = "Email address for Security Admin"
  default = "onaefe6@gmail.com"
  sensitive = true
}

variable "user_email" {
  type = string
  description = "Email address for User"
}

variable "hibp_api_key" {
  type = string
  description = "HIBP API Key passed by the User"
}

