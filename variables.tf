variable "security_email" {
  type        = string
  description = "Email address for Security Admin"
  sensitive   = true
}

variable "user_email" {
  type        = string
  description = "Email address for User"
}

variable "hibp_api_key" {
  type        = string
  description = "HIBP API Key passed by the User"
}

