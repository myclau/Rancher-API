#!/bin/bash

. rancher-lib.sh
search_rancher_serviceid
upgrade_service ${RANCHER_ENVIRONMENT} ${RANCHER_SERVICE} "${DOCKER_PULL_REPO}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
finish_upgrade ${RANCHER_ENVIRONMENT} ${RANCHER_SERVICE}
