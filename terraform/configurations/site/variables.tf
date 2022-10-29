variable "project" {
  type        = string
  description = "The google cloud project ID being managed"
}

variable "region" {
  type        = string
  description = "Region in which to create resources."
}

variable "dual_region" {
  type        = string
  default     = ""
  description = "Region in which to create higher-availability resources."
}

variable "domain" {
  type        = string
  description = "domain being served by the managed services"
}

variable "app-engine-services" {
  type        = list(string)
  description = "The services provided by App Engine (primarily used for ingress rule definition)"
}

variable "app-engine-service-account-roles" {
  type        = list(string)
  description = "The IAM roles granted to the App Engine Default Service account. Governs access to required google cloud resources."
}

variable "static_content_max_saved_states" {
  type        = number
  default     = 10
  description = "The maximum number of non-live versions of the static content to keep in the cloud storage bucket. Once reached, older versions will be deleted."
}
