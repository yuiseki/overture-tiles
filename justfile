#!/usr/bin/env just --justfile

cdk_dir := 'overture-tiles-cdk'
latest_release := '2025-11-19.0'
overture_bucket := 's3://overturemaps-us-west-2'

@_default:
    {{just_executable()}} --list

# Bootstrap the CDK environment
[group('setup')]
bootstrap-cdk:
    cd {{cdk_dir}} && npm install && npm run build

# Deploy the CDK stack
[group('setup')]
run-cdk:
    cd {{cdk_dir}} && npm run cdk deploy

# Destroy the CDK stack
[group('setup')]
destroy-cdk:
    cd {{cdk_dir}} && npm run cdk destroy

# Run a local test of the Docker container with the city of San Francisco. It skips uploading the generated PMTiles
[group('test')]
test-local:
    docker build -t overture-tiles:latest .
    -docker rm -f overture-test 2>/dev/null || true
    docker run --name overture-test \
        -e INPUT='{{overture_bucket}}/release/{{latest_release}}' \
        -e OUTPUT='sf-places.pmtiles' \
        -e THEME='places' \
        -e BBOX='-122.5247,37.7081,-122.3569,37.8324' \
        -e SKIP_UPLOAD='true' \
        overture-tiles:latest
    docker cp overture-test:/places.pmtiles ./sf-places.pmtiles
    docker rm overture-test
