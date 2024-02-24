# Automatically deploy app hosted in Github to Cloud Run using Cloud Build (cloudbuild.yaml) & avoid any “ClickOps” with Terraform
#
# Process explained in detail as part of following blog post:
# App architecture with reliability in mind: From Kubernetes to Serverless with GCP Cloud Build & Cloud Run
# https://foolcontrol.org/?p=4621
# 
# Youtube video:
# 

# Providers setup
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.13.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.13.0"
    }
  }
}

provider "google" {
    # Provider config options
    project = var.project
    region = var.region
    credentials = file(var.gcp_credentials)
}

provider "google-beta" {
    # Provider config options for google-beta
    project = var.project
    region = var.region
    credentials = file(var.gcp_credentials)
}


# Requires Service Usage API & Identity to be manually enabled: 
module "project-services" {

  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.4"

  project_id = var.project

  activate_apis = [
    "iam.googleapis.com", # Identity and Access Management (IAM) API
    "cloudresourcemanager.googleapis.com", # Cloud Resource Manager API
    "cloudbuild.googleapis.com", # Cloud Build API
    "artifactregistry.googleapis.com", # Artifacts Registry API
    "run.googleapis.com" # Cloud Run (Admin) API
  ]

  disable_services_on_destroy = true
}

# Create "cloud-sa" service account for Cloud Build & Run use
resource "google_service_account" "cloudbuild_service_account" {

  depends_on = [ module.project-services ]
  account_id = "cloud-sa"
}

# Define additional roles to assign to cloud-sa
variable "roles_to_assign" {
  description = "List of roles to assign"
  type        = list(string)
  default     = [
    "roles/iam.serviceAccountUser", # "default" role needed for Cloud Build & Cloud run
    "roles/logging.logWriter", # needed for logging
    "roles/artifactregistry.admin", # needed for "Authenticate with  GCP Artifacts Registry" in cloudbuild.yaml to work
    "roles/run.developer", # needed for cloud run to work
    "roles/run.admin" # needed for "Allow public (unauthenticated) access" in cloudbuild.yaml to work
    ] 
}

# Set additional roles to cloud-sa
resource "google_project_iam_binding" "cloud_sa_roles" {

  depends_on = [ module.project-services ]

  project = var.project
  count   = length(var.roles_to_assign)
  role    = var.roles_to_assign[count.index]

  members = [
    "serviceAccount:${google_service_account.cloudbuild_service_account.email}",
  ]
}

# Create atuf repo & add a cleanup policy for artifacts repo to keep only the most recent 3 versions of artifacts
resource "google_artifact_registry_repository" "atuf_repo" {

  depends_on = [ 
    google_project_iam_binding.cloud_sa_roles,
    module.project-services
  ]

  provider = google-beta
  project = var.project
  location = var.region
  repository_id = var.project_name
  description   = "${var.project_name_description} container repository"
  format        = "DOCKER"
  cleanup_policy_dry_run = false
  
  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count  = 3
    }
  }
}

# Create Cloud Build trigger
resource "google_cloudbuild_trigger" "atuf_trigger" {

  depends_on = [
    google_project_iam_binding.cloud_sa_roles,
    google_artifact_registry_repository.atuf_repo,
    module.project-services
  ]

  name     = var.cloudbuild_trigger_name
  location = var.region
  description = "Terraform generated trigger for ${var.project_name_description} GitHub repository"
  filename = "cloudbuild.yaml"
  service_account = google_service_account.cloudbuild_service_account.id

  # Please note: 
  # Connecting to Github repo using CloudBuild trigger won't be possible using Terraform and will have to be done using Google Console for the first time
  # otherwise will run into following error:
  # Error creating Trigger: googleapi: Error 400: Repository mapping does not exist. 
  # Please visit https://console.cloud.google.com/cloud-build/triggers;region=europe-west4/connect?project=fooctrl-312814 to connect a repository to your project
  # 
  # Explained in detail in Step 6 of:
  # "Automatically deploy app hosted in Github to Cloud Run using Cloud Build (cloudbuild.yaml) & avoid any “ClickOps” with Terraform" section on:
  # https://foolcontrol.org/?p=4621 & following Youtube video: ToDo: add link here
  github {
    owner = var.github_owner
    name  = var.github_repo_connection
    push {
      branch = "^main"
    }
  }
}

# Trigger the Cloud Build trigger
#
# Explained in detail in Step 5 of:
# "Automatically deploy app hosted in Github to Cloud Run using Cloud Build (cloudbuild.yaml) & avoid any “ClickOps” with Terraform" section on:
# https://foolcontrol.org/?p=4621 & following Youtube video: ToDo: add link here
resource "null_resource" "build_trigger_run" {

  depends_on = [google_cloudbuild_trigger.atuf_trigger]

  provisioner "local-exec" {
    command = "gcloud builds triggers run ${var.cloudbuild_trigger_name} --branch=main --region=${var.region}"
  }
}

# Polling mechanism to wait until "atuf-tf-trigger" build run has been completed successfully and there's a running Cloud Run service
#
# Explained in detail in Step 5 of:
# "Automatically deploy app hosted in Github to Cloud Run using Cloud Build (cloudbuild.yaml) & avoid any “ClickOps” with Terraform" section on:
# https://foolcontrol.org/?p=4621 & following Youtube video: ToDo: add link here
resource "null_resource" "build_trigger_run_wait" {

  depends_on = [
    google_cloudbuild_trigger.atuf_trigger,
    null_resource.build_trigger_run,
    google_project_iam_binding.cloud_sa_roles,
    module.project-services
  ]

  provisioner "local-exec" {
    command = "./scripts/wait_for_cloud_run.sh"
    interpreter = ["/bin/bash", "-c"]

    environment = {
      REGION  = var.region
      PROJECT = var.project
    }
  }
}

# Get data about running ATUF Cloud Run service deployed from cloudbuild.yaml
data "google_cloud_run_v2_service" "atuf" {
  depends_on = [
    google_cloudbuild_trigger.atuf_trigger, 
    null_resource.build_trigger_run,
    null_resource.build_trigger_run_wait,
    module.project-services
  ]

  location = var.region
  name     = var.project_name
}

# Map a custom domain using Cloud Run domain mapping (Limited availability and Preview)
# Reference: https://cloud.google.com/run/docs/mapping-custom-domains
#
# Explained in detail in Step 11 of:
# "Automatically deploy app hosted in Github to Cloud Run using Cloud Build (cloudbuild.yaml) & avoid any “ClickOps” with Terraform" section on:
# https://foolcontrol.org/?p=4621 & following Youtube video: ToDo: add link here
resource "google_cloud_run_domain_mapping" "default" {
  name     = var.cloud_run_domain
  location = data.google_cloud_run_v2_service.atuf.location
  metadata {
    namespace = var.project
  }
  spec {
    route_name = data.google_cloud_run_v2_service.atuf.name
  }

  depends_on = [
    google_cloudbuild_trigger.atuf_trigger, 
    null_resource.build_trigger_run_wait,
    data.google_cloud_run_v2_service.atuf,
    module.project-services
  ]
}

# Output info about Cloud Run deployment
output "atuf_cloud_run_service_info" {
  value = {
    service_name = data.google_cloud_run_v2_service.atuf.name
    service_location = data.google_cloud_run_v2_service.atuf.location
    service_project = data.google_cloud_run_v2_service.atuf.project
    service_url = data.google_cloud_run_v2_service.atuf.uri
    service_domain_value = google_cloud_run_domain_mapping.default.name
  }

  depends_on = [ 
    google_cloudbuild_trigger.atuf_trigger, 
    null_resource.build_trigger_run_wait,
    data.google_cloud_run_v2_service.atuf,
    google_cloud_run_domain_mapping.default
  ]
}