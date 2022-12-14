#!/bin/bash

fail() {
    echo "$@"
    exit 1
}

echo "begin to deploy GKE using gcloud ..."

echo "creating GKE cluster ..."
gcloud container clusters create $name \
    --cluster-version=1.23 \
    --no-enable-autoupgrade \
    --machine-type=e2-standard-4 \
    --num-nodes=1 \
    --network $network \
    --zone $zone \
    --project=$project_id || fail "Error: create GKE Cluster failed"

echo "get gke credential"
gcloud container clusters get-credentials $name \
    --zone $zone \
    --project=$project_id \
    --quiet > /dev/null || fail "Error: get GKE Cluster credential failed"

echo "deploying redis cluster..."
helm repo add my-repo https://charts.bitnami.com/bitnami
helm install my-release my-repo/redis-cluster --set "service.type=LoadBalancer,password=${redis_password},image-tag=${image_tag}" > /dev/null

waitTime=0
until [[ $(kubectl get svc my-release-redis-cluster -o jsonpath='{.status.loadBalancer.ingress[0].ip}') && $(kubectl get po -o jsonpath='{.items[].status.phase}') == 'Running' ]]; do
    sleep 10;
    waitTime=$(expr ${waitTime} + 10)
    echo "waited ${waitTime} secconds for vvp svc to be ready ..."
    if [ ${waitTime} -gt 300 ]; then
        echo "wait too long, failed."
        return 1
    fi
done

redis_cluster_ip=$(kubectl get svc my-release-redis-cluster -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "redis-cli -c -h $redis_cluster_ip -a $redis_password"