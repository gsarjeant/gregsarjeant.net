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

# This data source will be used to retrieve the project number where needed
# (currently only the storage bucket for the cloud function)
data "google_project" "project" {
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

# Create a blackhole storage bucket for unwanted traffic
resource "google_storage_bucket" "blackhole_storage_bucket" {
  name                        = "${var.project}_blackhole_storage_bucket"
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

# Make the blackhole storage bucket publicly readable so it can serve static content on the internet.
resource "google_storage_bucket_iam_member" "blackhole_allUsers" {
  bucket = google_storage_bucket.blackhole_storage_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Create a load balancer backend for the storage bucket.
# This will allow the load balancer to route requests for static content to the bucket.
resource "google_compute_backend_bucket" "blackhole_storage_bucket_backend" {
  name        = "${var.project}-blackhole-storage-bucket-backend"
  description = "Unmatched requests are routed to this bucket, which contains nothing and always returns a 404."
  bucket_name = google_storage_bucket.blackhole_storage_bucket.name
  enable_cdn  = true
}

# Create the app engine application that will host the API services
# NOTE: No longer using App Engine as of 2022-11-03, but I'm leaving this in the config
#       because App Engine can't be deleted from a project once enabled.
#       Leaving this in the terraform code will act as documentation to show that it's active.
resource "google_app_engine_application" "app" {
  project       = var.project
  location_id   = var.region
  database_type = "CLOUD_FIRESTORE"

  feature_settings {
    split_health_checks = true
  }
}

# Add firebase authentication to the serverless project
resource "google_firebase_project" "firebase" {
  provider = google-beta
  project  = var.project
}

# Cloud Run NEGs and load balancer backends

# Default Cloud Run NEG. Routes requests to the web service.
# The web service is a next.js application that provides the user-facing site. 
resource "google_compute_region_network_endpoint_group" "cloud_run_neg_default" {
  name                  = "${var.project}-cloud-run-neg-default"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = "web"
  }
}

# Service Accounts for Cloud Run
# Each cloud run service will run as a separate service account that has only the permissions
# required for that service.
resource "google_service_account" "cloud_run_web_service_account" {
  project      = var.project
  account_id   = "cloud-run-web"
  display_name = "Service Account for the Cloud Run 'web' service."
  description  = "Managed by terraform"
}

# Default Cloud Run Backend.
# Mapped to the default NEG that routes to the web service.
# This backend will be mapped to the bare domain.
#
# Enable Cloud CDN on this backend and cache all static content.
# The next.js site is statically rendered, so it can be safely cached.
# If needed, the cache can be invalidated on build, or I'll play with the headers.
# Setting serve_while_stale to 1 day to offset the occasional startup lag when all instances are spun down.
# (If the site doesn't get one request a day then who really cares if there's a startup lag of a few seconds on that request?)
resource "google_compute_backend_service" "cloud_run_default" {
  name = "${var.project}-cloud-run-backend-default"

  protocol        = "HTTP"
  port_name       = "http"
  timeout_sec     = 30
  security_policy = google_compute_security_policy.backend_policy.id
  enable_cdn      = true

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl       = 3600
    client_ttl        = 3600
    max_ttl           = 3600
    serve_while_stale = 86400
    cache_key_policy {
      include_host = true
    }
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg_default.id
  }
}

# NEG for Cloud Run API endpoints
# This NEG will route requests to the cloud run service whose name matches the first part of the URL path
# if such a service exists.
resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name                  = "${var.project}-cloud-run-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    url_mask = "/<service>"
  }
}

# Cloud Run API backend
# Mapped to the Cloud Run API NEG that routes requests to the appropriate service.
# This backend will be mapped to api.<domain>
resource "google_compute_backend_service" "cloud_run" {
  name = "${var.project}-cloud-run-backend"

  protocol        = "HTTP"
  port_name       = "http"
  timeout_sec     = 30
  security_policy = google_compute_security_policy.backend_policy.id

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  backend {
    group = google_compute_region_network_endpoint_group.cloud_run_neg.id
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
#   bare domain - route to static site cloud storage bucket
#   api.*       - route to serverless NEG
#   all others  - route to black hole cloud storage bucket (empty except for a 404 page)
resource "google_compute_url_map" "site_default" {
  name        = "${var.project}-site-default"
  description = "Load balancer routing rules for the ${var.domain} domain."

  # All requests that aren't matched by a host rule below are routed to the blackhole bucket
  default_service = google_compute_backend_bucket.blackhole_storage_bucket_backend.id

  # requests for the bare domain go to the static content bucket
  host_rule {
    hosts = [
      var.domain,
    ]
    path_matcher = "site"
  }

  # requests for the api go to the serverless backend (Cloud Run)
  host_rule {
    hosts = [
      "api.${var.domain}",
    ]
    path_matcher = "api"
  }

  path_matcher {
    name = "site"
    #default_service = google_compute_backend_bucket.static_content_backend.id
    default_service = google_compute_backend_service.cloud_run_default.id
  }

  path_matcher {
    name            = "api"
    default_service = google_compute_backend_service.cloud_run.id
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

# Create an artifact registry repository for API docker images
resource "google_artifact_registry_repository" "api_docker" {
  project       = var.project
  location      = var.region
  repository_id = "${var.project}-docker"
  description   = "Docker images for Cloud Run services that provide API functionality for gregsarjeant.net"
  format        = "DOCKER"
  labels        = local.common_labels
}

# Create a Cloud Armor edge security policy
# to block requests to the Load Balancer IP.
resource "google_compute_security_policy" "backend_policy" {
  name    = "backend-policy"
  project = var.project
  type    = "CLOUD_ARMOR"

  advanced_options_config {
    log_level = "VERBOSE"
  }

  # This rule will allow traffic that has an HTTP host header that matches the domain.
  # Anything else is probably a bot or scanner that is brute-forcing IPs.
  rule {
    action   = "allow"
    priority = "1000"
    match {
      expr {
        expression = "has(request.headers['host']) && request.headers['host'].contains('${var.domain}')"
      }
    }
    description = "Allow access to requests that match the domain."
    preview     = false
  }

  # Deny any traffic that isn't explicitly allowed by a higher-priority rule.
  rule {
    action   = "deny(404)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny by default"
  }
}
