variable "gcp_credentials" {
  type        = string
  description = "The contents of GCP credentials"
  default     = "~/.credentials/tf-deploy.json"
}

variable "region" {
  type = string
  description = "The GCP region"
  default = "europe-west4"
}

variable "project" {
  type = string
  description = "The GCP project ID"
  default = "fooctrl-dev"
}

variable "project_name" {
  type = string
  description = "Project name"
  default = "atuf"
}

variable "project_name_description" {
  type = string
  description = "Project name used in description"
  default = "ATUF"
}

variable "cloudbuild_trigger_name" {
  type = string
  description = "Cloud Build Trigger name"
  default = "atuf-tf-trigger"
}

variable "github_owner" {
  type = string
  description = "GitHub owner (username)"
  default = "AdnanHodzic"
}

variable "github_repo_connection" {
  type = string
  description = "GitHub repository name"
  default = "atuf.app"
}

variable "cloud_run_domain" {
  type = string
  description = "Cloud Run custom domain name"
  default = ""
}