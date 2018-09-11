#!/bin/bash

jenkins_global_rancher_api_url="https://xxxx.com/v2-beta"
jenkins_global_rancher_stacks_id_dev="1a1159"
jenkins_global_docker_pull_registry="my.docker.repo"
imagename=somedockerimage/name/project
#image version
tagversion=1.0.1


rancherservicename=stackname/servicename
jenkins_global_rancher_url="https://xxxx.com/"
# location for installing rancher cli
jenkins_global_ranchercli_path="~/rancher"

export RANCHER_ACCESS_KEY=asdjbasdbjakshdjahsjd
export RANCHER_SECRET_KEY=Xasjdajsdajskdjkajsdkjakd

#clean last time output
rm -f *.json

