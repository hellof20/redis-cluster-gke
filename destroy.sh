#!/bin/bash

echo "begin to destroy..."

echo "deleting gke cluster"
gcloud container clusters delete $name \
    --zone $zone \
    --project=$project_id \
    --quiet
    
 echo "destroy done"