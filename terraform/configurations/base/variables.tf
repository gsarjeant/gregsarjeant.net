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
  description = "Dual reqion in which to create higher-availability resources."
}

variable "enabled_apis" {
  type        = list(string)
  description = "The APIs that should be enabled to provide access to project features."
}

variable "kms_crypto_key_rotation_period" {
  type        = string
  description = "The amount of time in seconds after which to rotate the state bucket's KMS crypto key"
}

variable "admin_email_addresses" {
  type        = list(string)
  description = "email addresses of accounts that can manage the project via terraform"
}

variable "admin_iam_roles" {
  type        = list(string)
  description = "email addresses of accounts that can manage the project via terraform"
}

variable "tfstate_bucket_name" {
  type        = string
  description = "The name of the GCP storage bucket that will store terraform remote state."
}
