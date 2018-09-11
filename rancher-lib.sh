#!/bin/bash
[ -e debug-param.sh ] && . debug-param.sh || echo param will read from jenkins
export RANCHER_API_URL=${jenkins_global_rancher_api_url}
export RANCHER_ENVIRONMENT=${jenkins_global_rancher_stacks_id_dev}
export DOCKER_PULL_REPO=${jenkins_global_docker_pull_registry}
export DOCKER_IMAGE_NAME=${imagename}
export DOCKER_IMAGE_TAG=${tagversion}
export RANCHER_SERVICE_NAME=${rancherservicename}
export RANCHER_URL=${jenkins_global_rancher_url}
export RANCHERCLI=${jenkins_global_ranchercli_path}
export RANCHER_TOKEN="${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}"



function search_rancher_serviceid(){
	local stacknameinfo=(`eval ${RANCHERCLI} ps | grep service | grep -w ${RANCHER_SERVICE_NAME}`)
    if [ "${stacknameinfo[*]}" = "" ] ;
    then
        echo Error: service not found
        exit 1
    else
        local serviceid="${stacknameinfo[0]}"
        export RANCHER_SERVICE="${serviceid}"
        echo RANCHER_SERVICE="${serviceid}"
    fi

    if [ "${stacknameinfo[4]}" != "healthy" ] ;
    then
        echo Error: Not healthy deploy skip
        exit 1
    fi
    

}


function restart_service() {
    local environment=$1
    local service=$2
    local batchSize=$3
    local interval=$4

    curl --silent --write-out "Restart service - HTTP: %{http_code}\n" -u "${RANCHER_TOKEN}" \
        -X POST \
        -H 'Accept: application/json'  -H 'Content-Type: application/json' \
        -d '{"rollingRestartStrategy": {"batchSize": '${batchSize}', "intervalMillis": '${interval}'}}' \
        "${RANCHER_API_URL}/projects/${environment}/services/${service}/?action=restart" -o restart.log
    cat restart.log | jq . > restart.json && rm restart.log
}



function upgrade_service() {
    local environment=$1
    local service=$2
    local image=$3
    local isSidekick=${4-false}
    local sidekickindex=${5-0}
    local requestnodename=`[[ "${isSidekick}" = true ]] && echo "secondaryLaunchConfigs[${sidekickindex}]" || echo "launchConfig"`
    
    echo "${RANCHER_API_URL}/projects/${environment}/services/${service}"
    curl -u "${RANCHER_TOKEN}" \
        -X GET \
        -H 'Accept: application/json'  -H 'Content-Type: application/json' \
        "${RANCHER_API_URL}/projects/${environment}/services/${service}/" -o api.log
    cat api.log | jq . > api-response.json && rm api.log
    
    local launchConfig=`cat api-response.json | jq '.launchConfig'`
    local secondaryLaunchConfigs=`cat api-response.json | jq '.secondaryLaunchConfigs'`
    if [ "${launchConfig}" = null ] ;
    then 
        cat api-response.json
        exit 1
    else
        echo Response ok: api-response.json ok
    fi
    local appendsecondaryLaunchConfigs=`[ "${secondaryLaunchConfigs}" = null ] && echo "" || echo ",\"secondaryLaunchConfigs\": ${secondaryLaunchConfigs-null}"`
       echo "{\
            \"inServiceStrategy\": {\
                \"type\": \"inServiceUpgradeStrategy\",\
                \"batchSize\": 1,\
                \"intervalMillis\": 2000,\
                \"startFirst\": false,\
                \"launchConfig\": ${launchConfig-null}\
                ${appendsecondaryLaunchConfigs}\
            }\
        }" | jq . > update-request-data.json
    local updatedServiceStrategy=`cat update-request-data.json | jq ".inServiceStrategy.${requestnodename}.imageUuid=\"docker:${image}\""`
    echo "updatedServiceStrategy :"
    echo ${updatedServiceStrategy} | jq .
    

    
    curl --silent --write-out "Upgrade service - HTTP: %{http_code}\n" -u "${RANCHER_TOKEN}" \
        -X POST \
        -H 'Accept: application/json'  -H 'Content-Type: application/json' \
        -d "${updatedServiceStrategy}" \
        "${RANCHER_API_URL}/projects/${environment}/services/${service}/?action=upgrade" -o upgrade.log
    cat upgrade.log | jq . > upgrade-response.json && rm upgrade.log

    
}
function upgrade_sidekick_service() {
    local environment=$1
    local service=$2
    local image=$3
    local sideindex=${4-0}
    
    local service=$2
    upgrade_service ${environment} ${service} ${image} true ${sideindex}
}

function finish_upgrade() {
    local environment=$1
  	local service=$2

    echo "waiting for service to upgrade "
  	while true; do
        curl --silent -u "${RANCHER_TOKEN}" \
          -X GET \
          -H 'Accept: application/json'  -H 'Content-Type: application/json' \
          "${RANCHER_API_URL}/projects/${environment}/services/${service}/" -o waitingfinish.json
        local serviceState=` cat waitingfinish.json | jq '.state'`
        rm -f waitingfinish.json
      case $serviceState in
          "\"upgraded\"" )
              echo "completing service upgrade"
              curl --silent --write-out "Finish Upgrade - HTTP: %{http_code}\n" -u "${RANCHER_TOKEN}" \
                -X POST \
                -H 'Accept: application/json'  -H 'Content-Type: application/json' \
                -d '{}' \
                "${RANCHER_API_URL}/projects/${environment}/services/${service}/?action=finishupgrade" -o finishupgrade.log
            
              cat finishupgrade.log | jq . > finishupgrade-response.json && rm finishupgrade.log
    
              break ;;
          "\"upgrading\"" )
              echo "."
              sleep 9
              continue ;;
          *)
	            die "unexpected upgrade state: $serviceState" ;;
      esac
  	done
}

#search_rancher_serviceid
#upgrade_service ${RANCHER_ENVIRONMENT} ${RANCHER_SERVICE} "${DOCKER_PULL_REPO}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
#finish_upgrade ${RANCHER_ENVIRONMENT} ${RANCHER_SERVICE}
#restart_service ${RANCHER_ENVIRONMENT} ${RANCHER_SERVICE} 1 2000
