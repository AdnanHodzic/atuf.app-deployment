#!/bin/bash
# Polling mechanism to wait until "atuf-tf-trigger" Cloud Build run has been completed successfully and there's a running Cloud Run service.
# 
# Process explained in detail as part of following blog post:
# App architecture with reliability in mind: From Kubernetes to Serverless with GCP Cloud Build & Cloud Run
# https://foolcontrol.org/?p=4621
#
# Youtube video:
# 

# Function to check Cloud Run service URL status
check_cloud_run_status() {
  gcloud run services describe atuf --region="${REGION}" --platform=managed --project="${PROJECT}" --format=json | jq -r '.status.url' 2>/dev/null
}

# Poll until the Cloud Run service is ready
max_attempts=30
attempt=1
while [ $attempt -le $max_attempts ]; do
  echo "Checking Cloud Run status (Attempt $attempt of $max_attempts)"

  # Check the Cloud Run service URL status
  url_check=$(check_cloud_run_status)

  # If the service URL is ready, exit successfully
  if [ -n "$url_check" ]; then
    echo "Cloud Run service is ready!"
    exit 0
  fi

  # Increment the attempt counter
  ((attempt++))

  # Wait for a short duration before the next attempt
  sleep 10
done

# If the maximum number of attempts is reached and the service is still not ready, exit with an error
echo "Timed out waiting for Cloud Run service to be ready."
exit 1