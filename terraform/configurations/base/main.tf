provider "google" {
  project = var.project
  region  = var.region
}

terraform {
  backend "gcs" {
    bucket = "greg-sarjeant-personal-site-tfstate"
    prefix = "base"
  }
}

module "gcp-bootstrap" {
  source                         = "git@github.com:gsarjeant/gcp-bootstrap.git"
  project                        = var.project
  region                         = var.region
  dual_region                    = var.dual_region
  enabled_apis                   = var.enabled_apis
  kms_crypto_key_rotation_period = var.kms_crypto_key_rotation_period
  admin_email_addresses          = var.admin_email_addresses
  admin_iam_roles                = var.admin_iam_roles
  tfstate_bucket_name            = var.tfstate_bucket_name

  labels = {
    "project"       = "${var.project}",
    "source"        = "terraform"
    "configuration" = "base",
  }
}
