# note: Terraform doesn't allow you to use variable names in the backend configuration, which is kind of a bummer
terraform {
  backend "gcs" {
    bucket = "greg-sarjeant-personal-site-tfstate"
    prefix = "site"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}

locals {
  common_labels = {
    "source"        = "terraform",
    "configuration" = "site",
    "project"       = var.project,
  }
}

# Create a storage bucket for static content
resource "google_storage_bucket" "static_content_storage_bucket" {
  name                        = "${var.project}_static_content_storage_bucket"
  project                     = var.project
  location                    = var.dual_region
  uniform_bucket_level_access = true
  labels                      = local.common_labels
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  versioning {
    enabled = true
  }
  lifecycle {
    prevent_destroy = true
  }
  lifecycle_rule {
    condition {
      num_newer_versions = var.static_content_max_saved_states
      with_state         = "ANY"
    }
    action {
      type = "Delete"
    }
  }
}

# Make the storage bucket publicly readable so it can serve static content on the internet.
resource "google_storage_bucket_iam_member" "allUsers" {
  bucket = google_storage_bucket.static_content_storage_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Create a load balancer backend for the storage bucket.
# This will allow the load balancer to route requests for static content to the bucket.
resource "google_compute_backend_bucket" "static_content_backend" {
  name        = "${var.project}-domain-static-content-bucket"
  description = "Requests for static content are routed to the storage bucket via this backend."
  bucket_name = google_storage_bucket.static_content_storage_bucket.name
  enable_cdn  = true
}

# Create the app engine application that will host the API services
resource "google_app_engine_application" "app" {
  project       = var.project
  location_id   = var.region
  database_type = "CLOUD_FIRESTORE"

  feature_settings {
    split_health_checks = true
  }
}

# Only allow traffic from the load balancer or from a Google Cloud VPC
# i.e. block public access to the appspot URLs
#
# I've never been a big fan of using my IaC platform to deploy apps to the managed infrastructure,
# so terraform won't know the app engine service names
#
# TODO: Uncomment after deploying services
#resource "google_app_engine_service_network_settings" "app-engine-network-settings" {
#  for_each = toset(var.app-engine-services)
#
#  service = each.key
#  network_settings {
#    ingress_traffic_allowed = "INGRESS_TRAFFIC_ALLOWED_INTERNAL_AND_LB"
#  }
#}

# Add the Default App Engine service account to the datastore.user built-in role
#
# TODO: Uncomment and apply after App Engine instance is created
#       This causes the plan to fail if the service account doesn't already exist.
#data "google_app_engine_default_service_account" "gae_account" {
#}

#resource "google_project_iam_member" "gae_default_service_account_roles" {
#for_each = toset(var.app-engine-service-account-roles)
#project  = var.project
#role     = each.key
#member   = "serviceAccount:${data.google_app_engine_default_service_account.gae_account.email}"
#}

# Add firebase authentication to the serverless project
resource "google_firebase_project" "firebase" {
  provider = google-beta
  project  = var.project
}

# Create a network endpoint group (NEG) for the serverless (i.e. App Engine) app
resource "google_compute_region_network_endpoint_group" "appengine_neg" {
  name                  = "${var.project}-appengine-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  app_engine {
    url_mask = "/<service>"
  }
}

# Create a load balancer backend for the serverless NEG
# This will allow the load balancer to route API requests to the App Engine app.
resource "google_compute_backend_service" "appengine" {
  name = "${var.project}-appengine-backend"

  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.appengine_neg.id
  }
}

# Create a global IP address for the site.
resource "google_compute_global_address" "site" {
  name = "${var.project}-site"
}

# Create a google-managed SSL cert for the root domain and the api subdomain
resource "google_compute_managed_ssl_certificate" "site" {
  provider = google-beta

  name = "${var.project}-site"
  managed {
    domains = [
      var.domain,
      "api.${var.domain}",
    ]
  }
}

# Create a URL map to route requests to the appropriate backend:
#   default - route to bucket
#   api.*   - route to serverless NEG
resource "google_compute_url_map" "site_default" {
  name        = "${var.project}-site-default"
  description = "Load balancer routing rules for the ${var.domain} domain."

  default_service = google_compute_backend_bucket.static_content_backend.id

  # requests for the bare domain go to the static content bucket
  host_rule {
    hosts = [
      var.domain,
    ]
    path_matcher = "default"
  }

  #requests for the api go to the app engine app
  host_rule {
    hosts = [
      "api.${var.domain}",
    ]
    path_matcher = "api"
  }

  path_matcher {
    name            = "default"
    default_service = google_compute_backend_bucket.static_content_backend.id
  }

  path_matcher {
    name            = "api"
    default_service = google_compute_backend_service.appengine.id
  }
}

# Create an https proxy to route https traffic to the URL map
resource "google_compute_target_https_proxy" "site_default" {
  name = "${var.project}-site-default"

  url_map = google_compute_url_map.site_default.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.site.id
  ]
}

# Create a forwarding rule to forward incoming https traffic to the https proxy
# (This is what actually creates the load balancer as seen in the Google Cloud Console)
resource "google_compute_global_forwarding_rule" "site_default" {
  name = "${var.project}-lb-site-default"

  target     = google_compute_target_https_proxy.site_default.id
  port_range = "443"
  ip_address = google_compute_global_address.site.address
}

# Create networking resources to redirect all http traffic to https
resource "google_compute_url_map" "site_https_redirect" {
  name = "${var.project}-site-https-redirect"

  # The default redirect doesn't specify a host target,
  # so it is handled by the default backend (the storage bucket)
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }

  # Add a host rule to match requests to api.,
  # so that they can be redirected to the serverless NEG backend
  host_rule {
    hosts = [
      "api.${var.domain}",
    ]
    path_matcher = "api-https-redirect"
  }

  path_matcher {
    name = "api-https-redirect"
    default_url_redirect {
      host_redirect          = "api.${var.domain}"
      https_redirect         = true
      redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
      strip_query            = false
    }
  }
}

resource "google_compute_target_http_proxy" "site_https_redirect" {
  name    = "${var.project}-site-https-redirect"
  url_map = google_compute_url_map.site_https_redirect.id
}

resource "google_compute_global_forwarding_rule" "site_https_redirect" {
  name = "${var.project}-lb-site-https-redirect"

  target     = google_compute_target_http_proxy.site_https_redirect.id
  port_range = "80"
  ip_address = google_compute_global_address.site.address
}
