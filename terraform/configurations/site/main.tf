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

# Create a network endpoint group (NEG) for Cloud Run 
resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  name                  = "${var.project}-cloud-run-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    url_mask = "/<service>"
  }
}

# Create a load balancer backend for the serverless NEG
# This will allow the load balancer to route API requests to the appropriate serverlessApp Engine app.
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
    path_matcher = "site"
  }

  # requests for the api go to the serverless backend (Cloud Run)
  host_rule {
    hosts = [
      "api.${var.domain}",
    ]
    path_matcher = "api"
  }

  # requests for all other hosts to the serverless backend (Cloud Run)
  # this allows cloud armor rules to block unwanted traffic
  #
  # TODO: set up a black hole for this traffic
  host_rule {
    hosts = [
      "*",
    ]
    path_matcher = "default"
  }

  path_matcher {
    name            = "default"
    default_service = google_compute_backend_service.cloud_run.id
  }

  path_matcher {
    name            = "site"
    default_service = google_compute_backend_bucket.static_content_backend.id
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
  repository_id = "${var.project}-api-docker"
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

  # This rule blocks direct requests to the load balancer's IP, and anything
  # else that doesn't match the domain.
  # This traffic isn't coming from anything I care about.
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
    priority = "200000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny by default"
    preview     = false
  }

  # Leave default allow rule in place until testing is finished
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Allow by default until testing is finished"
  }
}
