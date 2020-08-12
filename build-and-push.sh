#!/bin/bash
# Create ECR repostiory if it does not exist
# Required environment:
#   image
#   tag
#   region
#   accountid
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY

# Acknowldge: code partly derived from https://github.com/kciter/aws-ecr-action/blob/master/entrypoint.sh

set -e

function main() {
  check "${image}" "image"
  check "${tag}" "tag"
  check "${region}" "region"
  check "${accountid}" "accountid"

  ACCOUNT_URL="${accountid}.dkr.ecr.${region}.amazonaws.com"
  export AWS_DEFAULT_REGION=${region}

  login
  docker_build "latest,${tag}" $accountid
  docker_push_to_ecr "latest,${tag}" $ACCOUNT_URL
}

function check() {
  if [ -z "${1}" ]; then
    >&2 echo "Unable to find the ${2} env variable."
    exit 1
  fi
}

function login() {
  echo "== START LOGIN"
  LOGIN_COMMAND=$(aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION)
  $LOGIN_COMMAND
  echo "== FINISHED LOGIN"
}

function docker_build() {
  echo "== START DOCKERIZE"
  local TAG=$1
  local docker_tag_args=""
  local DOCKER_TAGS=$(echo "$TAG" | tr "," "\n")
  for t in $DOCKER_TAGS; do
    docker_tag_args="$docker_tag_args -t $2/$image:$t"
  done

  docker build --build-arg version=${tag} -f Dockerfile $docker_tag_args .
  echo "== FINISHED DOCKERIZE"
}

function docker_push_to_ecr() {
  echo "== START PUSH TO ECR"
  local TAG=$1
  local DOCKER_TAGS=$(echo "$TAG" | tr "," "\n")
  for t in $DOCKER_TAGS; do
    docker push $2/${image}:$t
    echo ::set-output name=image::$2/$image:$t
  done
  echo "== FINISHED PUSH TO ECR"
}

main
