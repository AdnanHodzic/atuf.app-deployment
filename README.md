# atuf.app-deployment

This repo consists of [atuf.app - Amsterdam Toilet & Urinal Finder](http://atuf.app "atuf.app - Amsterdam Toilet & Urinal Finder") deployment code which will allow you to automatically deploy to GCP Cloud Run using Cloud Build (cloudbuild.yaml) & avoid any “ClickOps” with Terraform.

Deployment components:

* Dockerfile - atuf.app container image
* cloudbuild.yaml - Cloud Build CI/D configuration file for automated Cloud Run builds & deployments
* Terraform - automated IaC deployment of all necessary resources in GCP, main logic in:
  * main.tf
  * imports.tf
  * scripts/wait_for_cloud_run.sh 

Process explained in detail as part of "[App architecture with reliability in mind: From Kubernetes to Serverless with GCP Cloud Build & Cloud Run](https://foolcontrol.org/?p=4621 "App architecture with reliability in mind: From Kubernetes to Serverless with GCP Cloud Build & Cloud Run")" blog post and:

[![](http://foolcontrol.org/wp-content/uploads/2024/02/cloud-run-video-1.jpg)](https://www.youtube.com/watch?v=ksz1Vfg3ZQI)

[Youtube: From Kubernetes to Serverless with GCP Cloud Build & Cloud Run](https://www.youtube.com/watch?v=ksz1Vfg3ZQI) Youtube video.
