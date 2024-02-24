# Steps to take in order to import `data.google_cloud_run_service.atuf` Cloud Run service resource originating from cloudbuild.yaml
# provisioned with `google_cloudbuild_trigger.atuf_trigger` so it could be managed by Terraform and i.e destroyed along with other resources.
#
# Reference:
# Blog post: App architecture with reliability in mind: From Kubernetes to Serverless with GCP Cloud Build & Cloud Run
# https://foolcontrol.org/?p=4621
# 
# Cloud run service "Import" reference: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_service#import

# 1. In import block, replace {{project}}, {{location}}, {{name}} with actual service project, location, name from Outputs, i.e:
# id = "projects/fooctrl-312814/locations/europe-west4/services/atuf"
# and uncomment import block

# 2. Run Terraform plan with `generate-config-out` flag:
# terraform plan -generate-config-out=generated.tf
 
# 3. Review generated.tf (optional)

# 4. Run Terraform plan without any flags (there should be 1 new import):
# terraform plan
 
# 5. Run Terraform apply to import & Terraform manage previously external resource:
# terraform apply -auto-approve
 
# import {
#   id = "projects/ {{project}}/locations/{{location}}/services/atuf"
#   to = google_cloud_run_v2_service.default
# }